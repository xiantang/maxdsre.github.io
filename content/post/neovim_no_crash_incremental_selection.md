---
title: "Neovim: No Crash Incremental Selection"
date: 2024-07-11T23:16:09+08:00
author: "xiantang"
# lastmod: 
tags: ["neovim"]
categories: ["neovim"]
# images:
#   - ./post/golang/cover.png
description:
draft: false
---


When I use neovim treesitter incremental selection, it randomly crashes, but I cannot stable reproduce it. And I found some issues and complaints about this issue, but no solution. So I decide to write a blog post to record this issue and the solution.

related issues:
* https://www.reddit.com/r/neovim/comments/10wwkft/comment/j7qla2q/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button
* https://github.com/neovim/neovim/issues/24336
* https://github.com/neovim/neovim/issues/25254
* https://www.reddit.com/r/neovim/comments/18dn4qt/treesitter_incremental_selection/

## TL;DR

paste this `https://github.com/xiantang/nvim-conf/blob/7c0d6cbf6d9fd7b6a8960de887db1109332419bf/lua/plugins/treesitter.lua#L62-L132` into your neovim configuration file.


this is my treesitter incremental selection configuration:

```lua
incremental_selection = {
  enable = true,
  keymaps = {
          init_selection = true,
          node_incremental = "v",
          node_decremental = "<BS>",
  },
},

```


sometime when I use `v` to expand the selection, it crashes, and it's a Segmentation fault, and I have the report:

```shell
...
Core was generated by `nvim --embed render/src/lib.rs'.
Program terminated with signal SIGSEGV, Segmentation fault.
#0  0x00007f4067ec5f74 in ts_node_end_point () from /usr/lib/libtree-sitter.so.0
[Current thread is 1 (Thread 0x7f4067ccb740 (LWP 4597))]
(gdb) bt
#0  0x00007f4067ec5f74 in ts_node_end_point () from /usr/lib/libtree-sitter.so.0
#1  0x0000556dc036fbee in node_range (L=0x7f4067cab380) at /usr/src/debug/neovim/neovim-0.9.2/src/nvim/lua/treesitter.c:821
#2  0x00007f4067e1fef6 in lj_BC_FUNCC () at buildvm_x86.dasc:857
#3  0x00007f4067e32ab3 in lua_pcall (L=L@entry=0x7f4067cab380, nargs=nargs@entry=0, nresults=nresults@entry=0, errfunc=errfunc@entry=-2)
    at /usr/src/debug/luajit/luajit-2.0-4611e25/src/lj_api.c:1116
#4  0x0000556dc03639b1 in nlua_pcall (lstate=0x7f4067cab380, nargs=0, nresults=0) at /usr/src/debug/neovim/neovim-0.9.2/src/nvim/lua/executor.c:159
#5  0x0000556dc0373163 in nlua_typval_exec (lcmd=<optimized out>, lcmd_len=<optimized out>, name=<optimized out>, args=<optimized out>, argcount=0, special=false,
    ret_tv=0x0) at /usr/src/debug/neovim/neovim-0.9.2/src/nvim/lua/executor.c:1443
#6  0x0000556dc0374638 in nlua_typval_exec (ret_tv=0x0, special=false, argcount=0, args=0x0, name=0x556dc052730d ":lua", lcmd_len=<optimized out>,
    lcmd=0x556dc283d260 "require'nvim-treesitter.incremental_selection'.node_incremental()") at /usr/src/debug/neovim/neovim-0.9.2/src/nvim/memory.c:134
#7  ex_lua (eap=<optimized out>) at /usr/src/debug/neovim/neovim-0.9.2/src/nvim/lua/executor.c:1639
#8  0x0000556dc0515881 in execute_cmd0.constprop.0 (retv=0x7fffeda90c68, eap=0x7fffeda90cf0, errormsg=0x7fffeda90c60, preview=false)
    at /usr/src/debug/neovim/neovim-0.9.2/src/nvim/ex_docmd.c:1620
#9  0x0000556dc0309559 in do_one_cmd (cookie=0x0, fgetline=0x556dc031c830 <getexline>, cstack=0x7fffeda90eb0, flags=<optimized out>, cmdlinep=0x7fffeda90c58)
    at /usr/src/debug/neovim/neovim-0.9.2/src/nvim/ex_docmd.c:2279
#10 do_cmdline (cmdline=<optimized out>, fgetline=0x556dc031c830 <getexline>, cookie=0x0, flags=0) at /usr/src/debug/neovim/neovim-0.9.2/src/nvim/ex_docmd.c:578
#11 0x0000556dc03ca777 in nv_colon (cap=0x7fffeda915d0) at /usr/src/debug/neovim/neovim-0.9.2/src/nvim/normal.c:3247
#12 0x0000556dc03c4436 in normal_execute (state=0x7fffeda91550, key=<optimized out>) at /usr/src/debug/neovim/neovim-0.9.2/src/nvim/normal.c:1207
#13 0x0000556dc04931c7 in state_enter (s=0x7fffeda91550) at /usr/src/debug/neovim/neovim-0.9.2/src/nvim/state.c:99
#14 0x0000556dc03c3309 in normal_enter (cmdwin=<optimized out>, noexmode=<optimized out>) at /usr/src/debug/neovim/neovim-0.9.2/src/nvim/normal.c:497
#15 0x0000556dc01fb777 in main (argc=<optimized out>, argv=<optimized out>) at /usr/src/debug/neovim/neovim-0.9.2/src/nvim/main.c:642
```


But I have no idea how to fix it in neovim source code. After many times I updated the neovim and treesitter, the issue still exists. So I decide to disable the incremental selection feature. And implement a new incremental selection feature by myself. 

```lua
local ts_utils = require("nvim-treesitter.ts_utils")

local node_list = {}
local current_index = nil

function start_select()
        node_list = {}
        current_index = nil
        current_index = 1
        vim.cmd("normal! v")
end

function find_expand_node(node)
        local start_row, start_col, end_row, end_col = node:range()
        local parent = node:parent()
        if parent == nil then
                return nil
        end
        local parent_start_row, parent_start_col, parent_end_row, parent_end_col = parent:range()
        if
                start_row == parent_start_row
                and start_col == parent_start_col
                and end_row == parent_end_row
                and end_col == parent_end_col
        then
                return find_expand_node(parent)
        end
        return parent
end

function select_parent_node()
        if current_index == nil then
                return
        end

        local node = node_list[current_index - 1]
        local parent = nil
        if node == nil then
                parent = ts_utils.get_node_at_cursor()
        else
                parent = find_expand_node(node)
        end
        if not parent then
                vim.cmd("normal! gv")
                return
        end

        table.insert(node_list, parent)
        current_index = current_index + 1
        local start_row, start_col, end_row, end_col = parent:range()
        vim.fn.setpos(".", { 0, start_row + 1, start_col + 1, 0 })
        vim.cmd("normal! v")
        vim.fn.setpos(".", { 0, end_row + 1, end_col, 0 })
end

function restore_last_selection()
        if not current_index or current_index <= 1 then
                return
        end

        current_index = current_index - 1
        local node = node_list[current_index]
        local start_row, start_col, end_row, end_col = node:range()
        vim.fn.setpos(".", { 0, start_row + 1, start_col + 1, 0 })
        vim.cmd("normal! v")
        vim.fn.setpos(".", { 0, end_row + 1, end_col, 0 })
end

vim.api.nvim_set_keymap("n", "v", ":lua start_select()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "v", ":lua select_parent_node()<CR>", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<BS>", ":lua restore_last_selection()<CR>", { noremap = true, silent = true })

```

And it works well, and I can expand the selection by `v` and select the parent node by `v` and restore the last selection by `<BS>`.


if there have many people have the same issue, im willing to create a new tressitter plugin that let you config this altrenative incremental selection in treesitter configuration like as below:

```lua
no_crash_incremental_selection = {
  enable = true,
  keymaps = {
          init_selection = true,
          node_incremental = "v",
          node_decremental = "<BS>",
  },
},

