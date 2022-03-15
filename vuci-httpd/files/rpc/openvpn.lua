local rpc = require "vuci.rpc"
local ubus = require "ubus"
local uci = require "uci"

local M = {}

function M.del_client_tls_values(params)
  local c = uci.cursor()
  local section = params.section
  c:delete('openvpn', section, '_tls_cipher')
  c:delete('openvpn', section, 'client')
  c:delete('openvpn', section, 'auth')
  c:delete('openvpn', section, 'ca')
  c:delete('openvpn', section, 'key')
  c:delete('openvpn', section, 'cert')
  c:commit("openvpn")
end

function M.del_client_skey_values(params)
  local c = uci.cursor()
  local section = params.section
  c:delete('openvpn', section, 'secret')
  c:commit("openvpn")
end

function M.del_server_skey_values(params)
  local c = uci.cursor()
  local section = params.section
  c:delete('openvpn', section, 'secret')
  c:commit("openvpn")
end

function M.get_section_values(params)
  local c = uci.cursor()
  local section = params.section
  return c:get_all('openvpn', section)
end

function M.add_client_default_tls_values(params)
  local c = uci.cursor()
  local section = params.section
  c:set('openvpn', section, '_tls_cipher', 'all')
  c:set('openvpn', section, 'client', '1')
  c:set('openvpn', section, 'auth', 'sha1')
  c:commit("openvpn")
end

function M.del_server_tls_values(params)
  local c = uci.cursor()
  local section = params.section
  c:delete('openvpn', section, '_tls_cipher')
  c:delete('openvpn', section, '_tls_auth')
  c:delete('openvpn', section, 'tls_server')
  c:delete('openvpn', section, 'auth')
  c:delete('openvpn', section, 'ca')
  c:delete('openvpn', section, 'key')
  c:delete('openvpn', section, 'cert')
  c:delete('openvpn', section, 'dh')
  c:commit("openvpn")
end

function M.add_server_default_tls_values(params)
  local c = uci.cursor()
  local section = params.section
  c:set('openvpn', section, '_tls_cipher', 'all')
  c:set('openvpn', section, '_tls_auth', 'none')
  c:set('openvpn', section, 'tls_server', '1')
  c:set('openvpn', section, 'auth', 'sha1')
  c:commit("openvpn")
end

return M