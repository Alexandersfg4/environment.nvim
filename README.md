# environment.nvim 

A Neovim plugin for managing environment variables with project-specific overrides and persistence.

## Features

- 🛠️ Declare default environment variables during setup
- 🗂️ Project-specific overrides stored in `.idea/.nvim_env`
- 🔄 Automatic loading of variables on Neovim startup
- 📂 Auto-reload when changing project directories
- 🔒 Only allows modification of pre-declared variables
- 💻 Simple commands for variable management

## Installation

Using [Lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
  "github.com/Alexandersfg4/environment.nvim",
  config = function()
    require('environment').setup({
      variables = {
        -- Your default variables here
        API_KEY = "default_value",
        ENV = "development"
      }
    })
  end
}
```
## Commands
### :EnvSet KEY=value
Redeclare a project-specific environment variable
```
:EnvSet API_KEY=production_123456
```
### :EnvShow
Display all configured environment variables with their current values
```
API_KEY=production_123456
ENVIRONMENT=development
PORT=3000
```
