local CWD = unix.getcwd()
local PID_FILE = path.join(CWD, 'bin/redbean.pid')
local LOG_FILE = path.join(CWD, 'bin/redbean.log')
local BUILD = path.join(CWD, 'bin/redbean.com')
local PORT = 8080
local HOST = '127.0.0.1'

local WRITE_FLAGS = unix.O_CREAT | unix.O_WRONLY
local PERMISSIONS = 0644
local EXECUTABLE_PERMISSIONS = 0755

-- UTILS

function download(url, output)
  local status, headers, body = Fetch(url)

  if status == 200 then
    local fd = unix.open(output, WRITE_FLAGS, PERMISSIONS)
    if fd >= 0 then
      unix.write(fd, body)
      unix.close(fd)
      unix.chmod(output, EXECUTABLE_PERMISSIONS)
      print('File downloaded and saved: ' .. output)
    else
      print('Error, unable to open file for writing')
    end
  end
end

function is_running()
  return path.isfile(PID_FILE)
end

-- SCRIPTS

function get_deps()
  download('https://redbean.dev/zip.com', 'vendor/zip.com')
  download('https://redbean.dev/unzip.com', 'vendor/unzip.com')
end

function start()
  if is_running() then
    local fd = unix.open(PID_FILE, unix.O_RDONLY)
    local pid = unix.read(fd)
    print("redbean.com is already running at PID " .. pid)

    unix.close(fd)
    unix.exit(1)
  end

  local cmd = string.format(
    '%s -vv -d -L %s -P %s -p %d -l %s',
    BUILD, LOG_FILE, PID_FILE, PORT, HOST
  )

  local prog = assert(unix.commandv(BUILD))

  print('here')
  -- local ok, err = unix.execve(prog, {
  --   prog,
  --   '-vv', '-d',
  --   '-L', LOG_FILE,
  --   '-P', PID_FILE,
  --   '-p', PORT,
  --   '-l', HOST
  -- })

  -- print(ok)
  -- print(err)
end

function stop()
  if not is_running() then
    print('redbean.com is not running')
    unix.exit(0)
  end

  local fd = unix.open(PID_FILE, unix.O_RDONLY)
  local pid = unix.read(fd)
  unix.kill(pid, unix.SIGTERM)
  unix.unlink(PID_FILE)
end

local tasks = {
  ['--get-deps'] = get_deps,
  ['--start'] = start,
  ['--stop'] = stop
}

local fn = tasks[arg[1]]
if fn then
  fn()
  unix.exit(0)
end