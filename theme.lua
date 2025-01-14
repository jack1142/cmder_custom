local gitutil = require('gitutil')

-- Source: https://github.com/AmrEldib/cmder-powerline-prompt 

local arrowSymbol = ""
local branchSymbol = ""

-- I want to pass it from a function to an other...
local env

-- Resets the prompt 
function lambda_prompt_filter()
    local full_cwd = clink.get_cwd()
    local cwd = string.gsub(full_cwd, clink.get_env("home"), "~")

    -- env = clink.prompt.value:match('%[33;22;49m%((.+)%).+%[39;22;49m')
    -- I don't know much about these lua patterns but it seems to work
    env = clink.prompt.value:match('%[1;39;40m%((.+)%).+%[0m')
    
    local prompt = "\x1b]9;9;\"{full_cwd}\"\x07\x1b[37;44m {cwd} {git}{hg} {env}\x1b[0m\n\x1b[2m{lamb}\x1b[0m "
    prompt = string.gsub(prompt, "{full_cwd}", full_cwd)
    prompt = string.gsub(prompt, "{cwd}", cwd)
    prompt = string.gsub(prompt, "{lamb}", "λ")
    clink.prompt.value = prompt
end

--- copied from clink.lua
 -- Resolves closest directory location for specified directory.
 -- Navigates subsequently up one level and tries to find specified directory
 -- @param  {string} path    Path to directory will be checked. If not provided
 --                          current directory will be used
 -- @param  {string} dirname Directory name to search for
 -- @return {string} Path to specified directory or nil if such dir not found
local function get_dir_contains(path, dirname)

    -- return parent path for specified entry (either file or directory)
    local function pathname(path)
        local prefix = ""
        local i = path:find("[\\/:][^\\/:]*$")
        if i then
            prefix = path:sub(1, i-1)
        end
        return prefix
    end

    -- Navigates up one level
    local function up_one_level(path)
        if path == nil then path = '.' end
        if path == '.' then path = clink.get_cwd() end
        return pathname(path)
    end

    -- Checks if provided directory contains git directory
    local function has_specified_dir(path, specified_dir)
        if path == nil then path = '.' end
        local found_dirs = clink.find_dirs(path..'/'..specified_dir)
        if #found_dirs > 0 then return true end
        return false
    end

    -- Set default path to current directory
    if path == nil then path = '.' end

    -- If we're already have .git directory here, then return current path
    if has_specified_dir(path, dirname) then
        return path..'/'..dirname
    else
        -- Otherwise go up one level and make a recursive call
        local parent_path = up_one_level(path)
        if parent_path == path then
            return nil
        else
            return get_dir_contains(parent_path, dirname)
        end
    end
end

-- copied from clink.lua
-- clink.lua is saved under %CMDER_ROOT%\vendor
local function get_hg_dir(path)
    return get_dir_contains(path, '.hg')
end

-- adopted from clink.lua
-- clink.lua is saved under %CMDER_ROOT%\vendor
function colorful_hg_prompt_filter()

    -- Colors for mercurial status
    local colors = {
        clean = "\x1b[1;37;40m",
        dirty = "\x1b[31;1m",
    }

    if get_hg_dir() then
        -- if we're inside of mercurial repo then try to detect current branch
        local branch = get_hg_branch()
        if branch then
            -- Has branch => therefore it is a mercurial folder, now figure out status
            if get_hg_status() then
                color = colors.clean
            else
                color = colors.dirty
            end

            clink.prompt.value = string.gsub(clink.prompt.value, "{hg}", color.."("..branch..")")
            return false
        end
    end

    -- No mercurial present or not in mercurial file
    clink.prompt.value = string.gsub(clink.prompt.value, "{hg}", "")
    return false
end

---
 -- Get the status of working dir
 -- @return {bool}
---
function get_git_status()
    local file = io.popen("git status --no-lock-index --porcelain -s 2>nul")
    for line in file:lines() do
        file:close()
        return false
    end
    file:close()
    return true
end

-- adopted from clink.lua
-- Modified to add colors and arrow symbols
function colorful_git_prompt_filter()

    -- Colors for git status
    local colors = {
        clean = "\x1b[34;42m"..arrowSymbol.."\x1b[30;42m ",
        dirty = "\x1b[34;43m"..arrowSymbol.."\x1b[30;43m ",
    }

    local closingcolors = {
        clean = "", -- " \x1b[32;40m"..arrowSymbol,
        dirty = " ±" --\x1b[33;40m"..arrowSymbol,
    }

    local git_dir = gitutil.get_git_dir()
    if git_dir then
        -- if we're inside of git repo then try to detect current branch
        local branch = gitutil.get_git_branch(git_dir)
        if branch then
            -- Has branch => therefore it is a git folder, now figure out status
            if get_git_status() then
                color = colors.clean
                closingcolor = closingcolors.clean
            else
                color = colors.dirty
                closingcolor = closingcolors.dirty
            end

            --clink.prompt.value = string.gsub(clink.prompt.value, "{git}", color.."  "..branch..closingcolor)
            clink.prompt.value = string.gsub(clink.prompt.value, "{git}", color..branchSymbol.." "..branch..closingcolor)
            return false
        end
    end

    -- No git present or not in git file
    if env then
        clink.prompt.value = string.gsub(clink.prompt.value, "{git}", "\x1b[34;46m"..arrowSymbol)
    else
        clink.prompt.value = string.gsub(clink.prompt.value, "{git}", "\x1b[0;34m"..arrowSymbol)
    end
    return false
end


-- Modified to add colors and arrow symbols to env
function colorful_env_prompt_filter()
    local beforeColor = ""
    
    local git_dir = gitutil.get_git_dir()
    if git_dir then
        local branch = gitutil.get_git_branch(git_dir)
        if branch then
            -- Has branch => therefore it is a git folder, now figure out status
            if get_git_status() then
                if env then
                    beforeColor = "\x1b[32;46m"..arrowSymbol --cleen
                else
                    beforeColor = "\x1b[0;32m"..arrowSymbol --cleen
                end
            else
                if env then
                    beforeColor = "\x1b[33;46m"..arrowSymbol --dirty
                else
                    beforeColor = "\x1b[0;33m"..arrowSymbol --dirty
                end
            end
        end
    end

    if env then
        clink.prompt.value = string.gsub(clink.prompt.value, "{env}", beforeColor.."\x1b[30;46m "..env.." \x1b[36;49m"..arrowSymbol.."\x1b[0m")
    else
        clink.prompt.value = string.gsub(clink.prompt.value, "{env}", beforeColor)
    end
end

-- override the built-in filters
clink.prompt.register_filter(lambda_prompt_filter, 55)
clink.prompt.register_filter(colorful_hg_prompt_filter, 60)
clink.prompt.register_filter(colorful_git_prompt_filter, 60)
clink.prompt.register_filter(colorful_env_prompt_filter, 60)

-- helpful for colors
