--[[
LuCI - Lua Configuration Interface
]]--

local taskd = require "luci.model.tasks"
local docker = require "luci.docker"
local typecho_model = require "luci.model.typecho"
local m, s, o

m = taskd.docker_map("typecho", "typecho", "/usr/libexec/istorec/typecho.sh",
	translate("TypeCho"),
	translate("TypeCho is an streaming media service and a client–server media player platform, made by TypeCho, Inc.")
		.. translate("Official website:") .. ' <a href=\"https://www.typecho.tv/\" target=\"_blank\">https://www.typecho.tv/</a>')

local dk = docker.new({socket_path="/var/run/docker.sock"})
local dockerd_running = dk:_ping().code == 200
local docker_info = dockerd_running and dk:info().body or {}
local docker_aspace = 0
if docker_info.DockerRootDir then
	local statvfs = nixio.fs.statvfs(docker_info.DockerRootDir)
	docker_aspace = statvfs and (statvfs.bavail * statvfs.bsize) or 0
end

s = m:section(SimpleSection, translate("Service Status"), translate("TypeCho status:"))
s:append(Template("typecho/status"))

s = m:section(TypedSection, "main", translate("Setup"),
		(docker_aspace < 2147483648 and
		(translate("The free space of Docker is less than 2GB, which may cause the installation to fail.") 
		.. "<br>") or "") .. translate("The following parameters will only take effect during installation or upgrade:"))
s.addremove=false
s.anonymous=true

o = s:option(Value, "port", translate("Port").."<b>*</b>")
o.default = "9080"
o.datatype = "port"

o = s:option(Value, "image_name", translate("Image").."<b>*</b>")
o.rmempty = false
o.datatype = "string"
o.default = "joyqi/typecho:nightly-php7.4"
--if "x86_64" == docker_info.Architecture then
--end
o:value("joyqi/typecho:nightly-php7.4", "joyqi/typecho:nightly-php7.4")

local blocks = typecho_model.blocks()
local home = typecho_model.home()

o = s:option(Value, "config_path", translate("Config path").."<b>*</b>")
o.rmempty = false
o.datatype = "string"

local paths, default_path = typecho_model.find_paths(blocks, home, "Configs")
for _, val in pairs(paths) do
  o:value(val, val)
end
o.default = default_path

return m
