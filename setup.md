# Setup

The readme describes the wider process and the thoughts behind it, this document describes how to
get cracking with it.

## Install the skills and scripts

Skills are copied, not linked, so edits in the repo do not reach the installed
copy unless you copy them back:

```
cp -r examples/open-items examples/daily-priorities examples/end-of-day-wrap-up ~/.claude/skills/
mkdir -p ~/.claude/skills/bin
cp bin/extract-done bin/extract-open bin/slack-candidates ~/.claude/skills/bin/
```

`open-items` already points at `../bin/slack-candidates`. To use a different fetcher, replace every
`../bin/slack-candidates` in the installed `open-items/SKILL.md` with yours (it appears in the
`scripts:` line and in step 2). It must emit the contract described in step 2.

## Slack auth for `slack-candidates`

The fetcher needs a Slack user token, because `search.messages` refuses bot tokens. There are two
ways to get one:

### Ideally create a slack app

You'll likely need admin permission to allow this.

Create an app at <https://api.slack.com/apps>, add these user scopes, and
install it to the workspace: `search:read`, `channels:history`,
`groups:history`, `im:history`, `mpim:history`. 

You get an `xoxp-` token, put this in `~/.config/agentic-rituals/slack-token` or export it in
`$SLACK_TOKEN`

### Less ideally, copy secrets out of the browser session

If you can't install an app you can grab the credentials from your browser.

Log in to your slack workspace from your browser. You need a token and a cookie:

- Token `xoxc-…`
  - Firefox: Dev Tools -> Storage ->  Local Storage -> `https://app.slack.com` -> key
    `localConfig_v2` -> `teams`, find a `token`
  - Chrome: The local storage is at Dev Tools -> Application -> Local Storage.

- Cookie `xoxd-…`: 
  - Firefox: Dev Tools -> Storage -> Cookies -> `.slack.com` -> cookie named `d`
  - Chrome: Dev Tools -> Application -> Cookies

The session ends when you log out of Slack or Slack rotates it, at which point these tokens and
cookies stop working and need re-copying.

For this method you need both an `xoxc-` token and an `xoxd` cookie.

Put the `xoxc-` token in `~/.config/agentic-rituals/slack-token` or export it in `$SLACK_TOKEN`

Put the `xoxd-` cookie in `~/.config/agentic-rituals/slack-cookie` or export it in `$SLACK_COOKIE`

### Testing auth

```
~/.claude/skills/bin/slack-candidates 14 | jq '{user_id, collected_at,
  inbound: (.inbound_unreplied|length), outbound: (.outbound_open|length)}'
```

Non-zero exit with a Slack error name means the token or cookie is wrong or
expired.

## Slack Config

You can optionally list bot and alert channel names, one per line, in
`~/.config/agentic-rituals/slack-exclude` to have the fetcher script ignore them.

