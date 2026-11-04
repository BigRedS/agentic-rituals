#!/usr/bin/env bash
# Regression checks for bin/slack-candidates, against a fake `curl` so no real
# Slack is touched. The fake routes on the API method and the channel/query
# arguments, and answers from the fixtures below.
# Run from anywhere: tests/slack-candidates/run.sh
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
now=$(date +%s)
t() { echo "$((now - $1 * 3600)).000100"; }   # t <hours ago>
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir "$tmp/bin"

# Fixtures. Me is U_ME. Cases:
#   C1 mention from Jane, no reply from me           -> inbound
#   C2 mention from Jane, I replied in the thread    -> dropped
#   C3 my "I'll send" with nothing after             -> outbound
#   C4 my question, Jane answered                    -> dropped
#   D1 DM from Rick, last message                    -> inbound
#   C5 mention from Jane in an excluded channel      -> dropped
#   C6 mention 30 days ago (outside window)          -> dropped
m() { # m <channel> <channel-name> <is_im> <user> <hours-ago> <text> [thread_ts-hours-ago]
    local link="https://x.slack.com/archives/$1/p1"
    [ -n "${7:-}" ] && link="$link?thread_ts=$(t "$7")"
    jq -n --arg c "$1" --arg n "$2" --argjson im "$3" --arg u "$4" --arg ts "$(t "$5")" \
        --arg text "$6" --arg link "$link" \
        '{channel:{id:$c,name:$n,is_im:$im}, user:$u, ts:$ts, text:$text, permalink:$link}'
}
mentions=$(jq -s '{ok:true, messages:{paging:{pages:1}, matches:.}}' < <(
    m C1 acme false U_JANE 50 "<@U_ME> can you send the config?"
    m C2 acme false U_JANE 60 "<@U_ME> thoughts?" 60
    m C5 alerts false U_JANE 20 "<@U_ME> ping"
    m C6 acme false U_JANE 720 "<@U_ME> ancient"))
tome=$(jq -s '{ok:true, messages:{paging:{pages:1}, matches:.}}' < <(
    m D1 U_RICK true U_RICK 10 "any thoughts on the plan?"))
from_me=$(jq -s '{ok:true, messages:{paging:{pages:1}, matches:.}}' < <(
    m C3 acme false U_ME 40 "I'll send the URLs shortly"
    m C4 acme false U_ME 30 "does that work for you?"))
echo "$mentions" > "$tmp/search.mentions"; echo "$tome" > "$tmp/search.tome"; echo "$from_me" > "$tmp/search.from"
printf 'alerts\n' > "$tmp/exclude"

reply() { jq -n --arg ts "$(t "$2")" --arg u "$1" '{ts:$ts,user:$u,text:"x"}'; }
echo "{\"ok\":true,\"messages\":[$(reply U_JANE 60),$(reply U_ME 59)]}" > "$tmp/replies.C2"   # I replied
echo "{\"ok\":true,\"messages\":[$(reply U_ME 30),$(reply U_JANE 29)]}" > "$tmp/replies.C4"   # Jane answered
echo "{\"ok\":true,\"messages\":[$(reply U_ME 40)]}"                    > "$tmp/replies.C3"   # nothing after
echo "{\"ok\":true,\"messages\":[$(reply U_JANE 50)]}"                  > "$tmp/replies.C1"
echo "{\"ok\":true,\"messages\":[$(reply U_RICK 10)]}"                  > "$tmp/history.D1.before"
echo '{"ok":true,"messages":[]}'                                       > "$tmp/history.D1.after"

# The fake curl: last arg is the URL, --data-urlencode args are k=v.
cat > "$tmp/bin/curl" <<'FAKE'
#!/usr/bin/env bash
printf "%s\n" "$@" >> "$T/curl.args"
declare -A p; url=""; prev=""
for a in "$@"; do
    [ "$prev" = --data-urlencode ] && p[${a%%=*}]=${a#*=}
    prev=$a; url=$a
done
# honour -D <file> so the real script's header read does not fail
while [ $# -gt 0 ]; do [ "$1" = -D ] && : > "$2"; shift; done
case "${url##*/}" in
    auth.test)            echo '{"ok":true,"user_id":"U_ME"}' ;;
    search.messages)      case "${p[query]}" in
                              "<@U_ME> "*)  cat "$T/search.mentions" ;;
                              "to:me "*)    cat "$T/search.tome" ;;
                              "from:<@U_ME> "*) cat "$T/search.from" ;;
                          esac ;;
    conversations.replies) cat "$T/replies.${p[channel]}" ;;
    conversations.history) if [ -n "${p[latest]:-}" ]; then cat "$T/history.${p[channel]}.before"
                           else cat "$T/history.${p[channel]}.after"; fi ;;
    *) echo '{"ok":false,"error":"fake: unrouted"}' ;;
esac
printf '\n200'
FAKE
chmod +x "$tmp/bin/curl"

run() { T=$tmp PATH="$tmp/bin:$PATH" SLACK_TOKEN=xoxp-fake XDG_CONFIG_HOME="$tmp/cfg" \
        "${SC:-$here/../../bin/slack-candidates}" 14; }
mkdir -p "$tmp/cfg/agentic-rituals"; cp "$tmp/exclude" "$tmp/cfg/agentic-rituals/slack-exclude"

out=$(run)
fail=0
check() {  # <description> <jq expression that must print true>
    if [[ $(jq -r "$2" <<<"$out") == true ]]; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi
}
check "inbound is the unreplied mention and the DM" \
    '[.inbound_unreplied[].channel_id] | sort == ["C1","D1"]'
check "mention I replied to in-thread is dropped" '[.inbound_unreplied[].channel_id] | index("C2") | not'
check "excluded channel is dropped" '[.inbound_unreplied[].channel_id] | index("C5") | not'
check "message outside the window is dropped" '[.inbound_unreplied[].channel_id] | index("C6") | not'
check "outbound is only the unanswered message" '[.outbound_open[].channel_id] == ["C3"]'
check "thread_ts is carried from the permalink" '[.inbound_unreplied[] | select(.channel_id=="C1") | has("thread_ts")] == [false]'
check "collected_at present" '.collected_at | test("^[0-9]{4}-")'
check "user_id present" '.user_id == "U_ME"'

# xoxc- token: needs the cookie, and sends it as one header.
if T=$tmp PATH="$tmp/bin:$PATH" SLACK_TOKEN=xoxc-fake XDG_CONFIG_HOME="$tmp/nocfg" "${SC:-$here/../../bin/slack-candidates}" 14 >/dev/null 2>&1
then echo "FAIL xoxc- without cookie is refused"; fail=1; else echo "ok   xoxc- without cookie is refused"; fi
: > "$tmp/curl.args"
T=$tmp PATH="$tmp/bin:$PATH" SLACK_TOKEN=xoxc-fake SLACK_COOKIE="xoxd-a%2Bb" XDG_CONFIG_HOME="$tmp/cfg" "${SC:-$here/../../bin/slack-candidates}" 14 >/dev/null
if grep -qxF "Cookie: d=xoxd-a%2Bb" "$tmp/curl.args"
then echo "ok   cookie sent as a single Cookie header"; else echo "FAIL cookie header"; fail=1; fi

# An API error must abort with nothing on stdout.
echo '{"ok":false,"error":"ratelimited_or_whatever"}' > "$tmp/replies.C1"
if err_out=$(run 2>/dev/null); then echo "FAIL API error aborts"; fail=1
elif [ -z "$err_out" ]; then echo "ok   API error aborts with empty stdout"
else echo "FAIL API error left partial stdout"; fail=1; fi
exit $fail
