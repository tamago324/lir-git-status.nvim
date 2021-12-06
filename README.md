# lir-git-status.nvim

Git status integration of [lir.nvim](https://github.com/tamago324/lir.nvim)


## Installation

```
Plug 'tamago324/lir.nvim'
Plug 'nvim-lua/plenary.nvim'
Plug 'tamago324/lir-git-status.nvim'
```

## Usage

```
require'lir.git_status'.setup({
  show_ignored = false
})
```

### Change highlights groups

```viml
highlight link LirGitStatusBracket Comment
highlight link LirGitStatusIndex Special
highlight link LirGitStatusWorktree WarningMsg
highlight link LirGitStatusUnmerged ErrorMsg
highlight link LirGitStatusUntracked Comment
highlight link LirGitStatusIgnored Comment
```


## Contributing

* All contributions are welcome.


## Credit

* [kristijanhusak/defx-git](https://github.com/kristijanhusak/defx-git)
* [lambdalisue/fern-git-status.vim](https://github.com/lambdalisue/fern-git-status.vim)
* [kyazdani42/nvim-tree.lua](https://github.com/kyazdani42/nvim-tree.lua)


## Screenshots

![](https://github.com/tamago324/images/blob/master/lir-git-status.nvim/lir-git-status1.png)

## License

MIT
