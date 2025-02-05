---@class EnvConfig
---@field dir string Directory to store environment files
---@field env_file string Name of the environment file
---@field variables table<string, string> Default environment variables

local M = {}

---@type EnvConfig
local default_config = {
	dir = ".idea",
	env_file = ".nvim_env",
	variables = {},
}

local config = vim.deepcopy(default_config)

---Creates the environment directory if it doesn't exist
local function create_env_dir()
	if vim.fn.isdirectory(config.dir) == 0 then
		vim.fn.mkdir(config.dir, "p")
	end
end

---Gets the full path to the environment file
---@return string
local function get_env_path()
	return table.concat({ vim.fn.getcwd(), config.dir, config.env_file }, "/")
end

---Reads environment variables from file
---@param path string Path to environment file
---@return table<string, string>
function M._read_env_file(path)
	local ok, lines = pcall(vim.fn.readfile, path)
	if not ok then
		return {}
	end

	local env = {}
	for _, line in ipairs(lines) do
		local key, value = line:match("^([^=]+)=(.+)$")
		if key and value then
			env[key] = value
		end
	end
	return env
end

---Saves environment variables to file
---@param key string
---@param value string
function M._save_env_file(key, value)
	create_env_dir()
	local env_path = get_env_path()

	-- Read existing variables
	local env = M._read_env_file(env_path)

	-- Update with new value
	env[key] = value

	-- Convert to lines and save
	local lines = {}
	for k, v in pairs(env) do
		table.insert(lines, string.format("%s=%s", k, v))
	end

	vim.fn.writefile(lines, env_path)
end

---Loads environment variables from file
function M._load_env()
	local env_path = get_env_path()
	if vim.fn.filereadable(env_path) ~= 1 then
		return
	end

	local project_env = M._read_env_file(env_path)
	for key, value in pairs(project_env) do
		if config.variables[key] then -- Only load declared variables
			vim.env[key] = value
		end
	end
end

---Sets up plugin commands
function M._setup_commands()
	-- Set environment variable command
	vim.api.nvim_create_user_command("EnvSet", function(opts)
		local key, value = opts.args:match("^([^=]+)=(.+)$")
		if not key or not value then
			vim.notify("Invalid format. Use: EnvSet KEY=value", vim.log.levels.ERROR)
			return
		end

		if not config.variables[key] then
			vim.notify("Variable not declared in setup: " .. key, vim.log.levels.ERROR)
			return
		end

		vim.env[key] = value
		M._save_env_file(key, value)
	end, { nargs = 1, desc = "Set environment variable" })

	-- Show environment variables command
	vim.api.nvim_create_user_command("EnvShow", function()
		local output = {}
		for key in pairs(config.variables) do
			table.insert(output, string.format("%s=%s", key, vim.env[key] or ""))
		end
		print(table.concat(output, "\n"))
	end, { desc = "Show current environment variables" })
end

---Main setup function
---@param user_config? EnvConfig
function M.setup(user_config)
	-- Merge user configuration with defaults
	config = vim.tbl_deep_extend("force", default_config, user_config or {})

	-- Set default values for all declared variables
	for key, value in pairs(config.variables) do
		if vim.env[key] == nil then
			vim.env[key] = value
		end
	end

	-- Load project-specific environment variables
	M._load_env()

	-- Set up commands and auto-reload
	M._setup_commands()
	M._setup_autoconfig()
end

---Sets up auto-configuration triggers
function M._setup_autoconfig()
	vim.api.nvim_create_autocmd({ "VimEnter", "DirChanged" }, {
		pattern = "*",
		callback = function()
			M._load_env()
			vim.notify("Environment variables reloaded", vim.log.levels.INFO)
		end,
		desc = "Reload environment variables",
	})
end

return M
