local CWD = unix.getcwd()
local PORT = '8081'
local HOST = '127.0.0.1'

-- vendor
local REDBEAN = path.join(CWD, 'vendor/redbean.com')

-- build
local BUILD = path.join(CWD, 'bin/redbean.com')
local PID_FILE = path.join(CWD, 'bin/redbean.pid')
local LOG_FILE = path.join(CWD, 'bin/redbean.log')
local IMG_DIR = path.join(CWD, 'bin/img')

function is_running()
  return path.isfile(PID_FILE)
end

function start()
  if is_running() then
    local fd = unix.open(PID_FILE, unix.O_RDONLY)
    local pid = unix.read(fd)
    print('Redbean is already running at PID ' .. pid)
    unix.close(fd)
  end

  local cmd = string.format(
    '%s -vv -d -L %s -P %s -p %d -l %s',
    BUILD, LOG_FILE, PID_FILE, PORT, HOST
  )

  if assert(unix.fork()) == 0 then
    local prog = assert(unix.commandv(BUILD))

    local ok, err = unix.execve(prog, {
      '-vv', '-d',
      '-L', LOG_FILE,
      '-P', PID_FILE,
      '-p', PORT,
      '-l', HOST
    })

    if err then
      print('Unable to start Redbean')
      print(prog)
      error(err)
    end

    unix.kill(unix.getppid(), unix.SIGTERM)
    unix.exit(0)
  end
end

function stop()
  if is_running() then
    local fd = unix.open(PID_FILE, unix.O_RDONLY)
    local pid = unix.read(fd)
    local ok, err = unix.kill(pid, unix.SIGKILL)

    if err then
      error('Unable to kill process with PID:' .. pid)
    elseif ok then
      print('Process killed: ' .. pid)
    end
  else
    print('No PID file found')
  end
end

start()