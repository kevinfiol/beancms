local WRITE_FLAGS = unix.O_CREAT | unix.O_WRONLY
local PERMISSIONS = 0644
local EXECUTABLE_PERMISSIONS = 0755

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

function get_deps()
  download('https://redbean.dev/zip.com', 'vendor/zip.com')
  download('https://redbean.dev/unzip.com', 'vendor/unzip.com')
  download('https://redbean.dev/redbean-3.0.0.com', 'vendor/redbean.com')
end

local tasks = {
  ['--get-deps'] = get_deps
}

local fn = tasks[arg[1]]
if fn then fn() end