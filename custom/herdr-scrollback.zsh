# herdr-scrollback — inside herdr panes, run coding agents inline (no alternate
# screen) so the transcript lives in herdr's pane scrollback. That makes mouse
# wheel / PgUp / copy-mode scrolling work, including from `herdr --remote`.
#
#   claude: CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1 (forces classic renderer,
#           overrides the saved `tui` setting)
#   codex:  --no-alt-screen   (same as tui.alternate_screen = "never")
#   pi:     --tui-mode regular
#
# Outside herdr agent commands are unchanged. The private flag helper remains
# available so helpers that launch into a Herdr pane can prepare the command.

# _herdr_scrollback_flags <agent> [args...] → sets $reply to the extra flags.
# Only added for interactive launches, never for subcommands / print mode.
if [[ ${HERDR_USE_TUI_COMPAT_CODING_AGENT-0} == 1 ]]; then
_herdr_scrollback_flags() {
  local agent=$1; shift
  typeset -ga reply=()
  case $agent in
    codex)
      case ${1-} in exec|e|review|login|logout|mcp|mcp-server|app-server|completion|sandbox|debug|apply|a|cloud|features|doctor|help|-h|--help|-V|--version) return ;; esac
      (( ${@[(Ie)--no-alt-screen]} )) || reply=(--no-alt-screen) ;;
    pi)
      case ${1-} in install|remove|uninstall|update|list|config|auth) return ;; esac
      local a
      for a in "$@"; do
        case $a in -p|--print|--mode|--mode=*|--tui-mode|--tui-mode=*|-h|--help|-v|--version) return ;; esac
      done
      reply=(--tui-mode regular) ;;
  esac
}
fi

[[ -n ${HERDR_ENV-} ]] || return 0

export CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN=1

codex() { _herdr_scrollback_flags codex "$@"; command codex "${reply[@]}" "$@"; }
pi()    { _herdr_scrollback_flags pi "$@";    command pi "${reply[@]}" "$@"; }
