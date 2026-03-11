#!/bin/bash
tmux list-panes -sF "#{pane_id}" | xargs -I{} tmux show-option -pv -t {} @project_root 2>/dev/null | head -1
