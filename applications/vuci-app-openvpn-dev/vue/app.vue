<template>
  <div>
    <a-row :gutter="[0,0]">
      <a-col :span="24">
        <a-divider orientation="left">
          Available Instances
        </a-divider>
        <a-table :columns="columns" :data-source="sections" bordered>
          <template v-slot:instance="record">
            <a v-text="record['_name']"></a>
          </template>
          <template v-slot:role="record">
            <span v-text="record.type"></span>
          </template>
          <template v-slot:status="record">
            <span>
              <a-tag v-if="setStatusName(record['.name'], record.enable) === 'Enabled'" color="blue">
                {{setStatusName(record['.name'], record.enable)}}
              </a-tag>
              <a-tag v-if="setStatusName(record['.name'], record.enable) === 'Active'" color="green">
                {{setStatusName(record['.name'], record.enable)}}
              </a-tag>
              <a-tag v-if="setStatusName(record['.name'], record.enable) === 'Inactive'" color="orange">
                {{setStatusName(record['.name'], record.enable)}}
              </a-tag>
              <a-tag v-if="setStatusName(record['.name'], record.enable) === 'Disabled'" color="red">
                {{setStatusName(record['.name'], record.enable)}}
              </a-tag>
              <a-tag v-if="setStatusName(record['.name'], record.enable) === ''">
                Unknown
              </a-tag>
            </span>
          </template>
          <template v-slot:action="record">
            <a-button v-if="record.enable === '0'" type="primary" @click="actionEnable(record['.name'])">
              Enable
            </a-button>
            <a-button v-if="record.enable === '1'" type="danger" @click="actionDisable(record['.name'])">
              Disable
            </a-button>
            <a-divider type="vertical" />
            <a-button @click="edit(record['.name'], record.type)">
              Edit
            </a-button>
            <a-divider type="vertical" />
            <a-popconfirm @confirm="del(record['.name'])" :title="'Do you really want to delete ' + record['_name'] + '?'">
              <a>Delete</a>
            </a-popconfirm>
          </template>
        </a-table>
      </a-col>
    </a-row>
    <a-row :gutter="[0,10]">
      <a-col :span="24">
        <a-divider orientation="left">
          Create instance
        </a-divider>
        <a-form-model layout="inline" :model="formInline" @submit="add(formInline.name, formInline.role)" @submit.native.prevent>
          <a-form-model-item label="Name">
            <a-input v-model="formInline.name" required placeholder="Name of instance">
            </a-input>
          </a-form-model-item>
          <a-form-model-item label="Role">
            <a-select style="width: 115px;" name="type" required v-model="formInline.role" placeholder="insert role">
              <a-select-option v-for="option in formInline.options" :key="option">
                {{ option }}
              </a-select-option>
            </a-select>
          </a-form-model-item>
          <a-form-model-item>
            <a-button
              :html-type="(formInline.name !== '' && formInline.role !== '') ? 'submit' : 'button'"
              type="primary"
              :disabled="formInline.name === '' || formInline.role === ''"
            >
              Add
            </a-button>
          </a-form-model-item>
        </a-form-model>
      </a-col>
    </a-row>

    <a-modal :footer="null" :title="modalTitle" v-model="editModal" :width="800" :afterClose="modalClose">
      <vuci-form uci-config="openvpn" v-if="editModal" @applied="adjustOptions">
        <vuci-named-section :name="editorSection" v-slot="{ s }">
          <vuci-form-item-switch :uci-section="s" :label="'Enable'" name="enable" :initial="false" true-value="1" false-value="0" :help="'To enable the instance'"/>
          <vuci-form-item-select :uci-section="s" :label="'Authentication'" name="_auth" :options="auth" required/>
          <vuci-form-item-input :uci-section="s" :label="'Port'" name="port" rules="port" placeholder="1192"/>
          <vuci-form-item-input :uci-section="s" :label="'Remote host/IP address'" name="remote" rules="host" placeholder="192.168.1.1." depend="_auth == 'tls' || 'skey'"/>
          <!-- CLIENT -->
          <div v-if="editorType === 'client'">
            <!-- TLS -->
            <vuci-form-item-input :uci-section="s" :label="'Remote network IP address'" name="remote_ip" @change="getValue" :rules="validateRemoteNetworkIp" placeholder="192.168.1.0" depend="_auth == 'tls'" />
            <vuci-form-item-input :uci-section="s" :label="'Remote network Netmask'" name="remote_netmask" @change="getValue" :rules="validateRemoteMask" placeholder="255.255.255.0" depend="_auth == 'tls'"/>
            <vuci-form-upload :uci-section="s" :label="'Certificate authority'" name="ca" depend="_auth == 'tls'" :sectionNaming="uploadedFileWithSectionName"/>
            <vuci-form-upload :uci-section="s" :label="'Client certificate'" name="cert" depend="_auth == 'tls'" :sectionNaming="uploadedFileWithSectionName"/>
            <vuci-form-upload :uci-section="s" :label="'Client key'" name="key" depend="_auth == 'tls'" :sectionNaming="uploadedFileWithSectionName"/>
            <!-- STATIC KEY -->
            <vuci-form-item-input :uci-section="s" :label="'Local tunnel endpoint IP'" name="local_ip" rules="ipaddr" placeholder="192.168.1.1" depend="_auth == 'skey'" />
            <vuci-form-item-input :uci-section="s" :label="'Remote tunnel endpoint IP'" name="remote_ip" rules="ipaddr" placeholder="192.168.1.1" depend="_auth == 'skey'" />
            <vuci-form-item-input :uci-section="s" :label="'Remote network IP address'" name="network_ip" @change="getValue" :rules="validateRemoteNetworkIp" placeholder="192.168.1.0" depend="_auth == 'skey'" />
            <vuci-form-item-input :uci-section="s" :label="'Remote network netmask'" name="network_mask" @change="getValue" :rules="validateRemoteMask" placeholder="192.168.1.1" depend="_auth == 'skey'" />
            <vuci-form-upload :uci-section="s" :label="'Static key'" name="secret" depend="_auth == 'skey'" :sectionNaming="uploadedFileWithSectionName"/>
          </div>
          <div v-if="editorType === 'server'">
            <!-- SERVER -->
              <!-- TLS -->
            <vuci-form-item-input :uci-section="s" :label="'Virtual network IP address'" name="server_ip" rules="ipaddr" placeholder="192.168.1.1" depend="_auth == 'tls'" />
            <vuci-form-item-input :uci-section="s" :label="'Virtual network netmask'" name="server_netmask" rules="netmask4" placeholder="255.255.255.0" depend="_auth == 'tls'"/>
            <vuci-form-upload :uci-section="s" :label="'Certificate authority'" name="ca" depend="_auth == 'tls'" :sectionNaming="uploadedFileWithSectionName"/>
            <vuci-form-upload :uci-section="s" :label="'Server certificate'" name="cert" depend="_auth == 'tls'" :sectionNaming="uploadedFileWithSectionName"/>
            <vuci-form-upload :uci-section="s" :label="'Server key'" name="key" depend="_auth == 'tls'" :sectionNaming="uploadedFileWithSectionName"/>
            <vuci-form-upload :uci-section="s" :label="'Diffie Hellman parameters'" name="dh" depend="_auth == 'tls'" :sectionNaming="uploadedFileWithSectionName"/>
              <!-- STATIC KEY -->
            <vuci-form-item-input :uci-section="s" :label="'Local tunnel endpoint IP'" name="local_ip" rules="ipaddr" placeholder="192.168.1.1" depend="_auth == 'skey'" />
            <vuci-form-item-input :uci-section="s" :label="'Remote tunnel endpoint IP'" name="remote_ip" rules="ipaddr" placeholder="192.168.1.1" depend="_auth == 'skey'" />
            <vuci-form-item-input :uci-section="s" :label="'Remote network IP address'" name="network_ip" rules="ipaddr" placeholder="192.168.1.0" depend="_auth == 'skey'" />
            <vuci-form-item-input :uci-section="s" :label="'Remote network netmask'" name="network_mask" rules="ipaddr" placeholder="192.168.1.1" depend="_auth == 'skey'" />
            <vuci-form-upload :uci-section="s" :label="'Static key'" name="secret" depend="_auth == 'skey'" :sectionNaming="uploadedFileWithSectionName"/>
          </div>

        </vuci-named-section>

      </vuci-form>
    </a-modal>
  </div>
</template>

<script>
/* eslint dot-notation: ["error", { "allowKeywords": false }] */
/* eslint dot-notation: ["error", { "allowPattern": "^[a-z]+(_[a-z]+)+$" }] */
export default {
  data () {
    return {
      config: 'openvpn',
      auth: ['tls', 'skey'],
      editModal: false,
      uploadedFileName: '',
      editorSection: '',
      editorType: '',
      latestSection: '',
      networkLanIp: '',
      networkLanMask: '',
      remoteNetworkIp: '',
      remoteNetworkMask: '',
      maskNumberConverted: '',
      ubusData: {},
      compRemoteFirstIp: '',
      compRemoteLastIp: '',
      sections: [],
      columns: [
        { key: 'instance', title: 'Instance name', width: 175, scopedSlots: { customRender: 'instance' } },
        { key: 'role', title: 'Role', width: 100, scopedSlots: { customRender: 'role' } },
        { key: 'status', title: 'Status', width: 150, scopedSlots: { customRender: 'status' } },
        { key: 'action', title: 'Actions', width: 150, scopedSlots: { customRender: 'action' } }
      ],
      formInline: {
        name: '',
        role: '',
        options: [
          'client', 'server'
        ]
      }
    }
  },
  timers: {
    load: { time: 1500, autostart: true, immediate: true, repeat: true }
  },
  methods: {
    isIPv4Addr (ip) {
      const iPv4RegEx = /^(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
      if (iPv4RegEx.test(ip)) {
        return true
      } else {
        return false
      }
    },
    modalClose () {
      this.editorSection = ''
    },
    isMask (mask) {
      const netMaskRegEx = /^((128|192|224|240|248|252|254)\.0\.0\.0)|(255\.(((0|128|192|224|240|248|252|254)\.0\.0)|(255\.(((0|128|192|224|240|248|252|254)\.0)|255\.(0|128|192|224|240|248|252|254)))))$/
      if (netMaskRegEx.test(mask)) {
        return true
      } else {
        return false
      }
    },
    async getLanNetwork () {
      await this.$uci.load('network')
      this.networkLanIp = this.$uci.get('network', 'lan', 'ipaddr')
      this.networkLanMask = this.$uci.get('network', 'lan', 'netmask')
    },
    validateRemoteNetworkIp (value) {
      const lanIpInt = this.ip2num(this.networkLanIp) - 1
      const lanMaskConverted = this.maskGetRemaining(this.networkLanMask) - 1
      const remoteIpInt = this.ip2num(value)
      if (remoteIpInt >= lanIpInt && remoteIpInt <= (lanIpInt + lanMaskConverted)) {
        return `IP address ${value} must not fall within the lan's range`
      } else if (this.isIPv4Addr(value) === false) {
        return 'Entered value must be a valid IPv4 address'
      }
    },
    validateRemoteMask (value) {
      const remoteIp = this.remoteNetworkIp
      const remoteIpInt = this.ip2num(remoteIp)
      const remoteMask = value
      this.getIpRangeFromAddressAndNetmask(remoteIp, remoteMask)
      const remoteNetworkFirstIp = this.ip2num(this.compRemoteFirstIp)

      if (remoteIpInt !== remoteNetworkFirstIp) {
        return `Incompatible subnet for remote IP ${remoteIp}`
      } else if (this.isIPv4Addr(value) === false) {
        return 'Entered value is not a valid netmask'
      }
    },
    del (name) {
      this.$spin()
      this.$uci.del('openvpn', name)
      this.$uci.save().then(() => {
        this.$uci.apply().then(() => {
          this.load()
          this.$spin(false)
        })
      })
    },
    getValue (value) {
      setTimeout(() => {
        // eslint-disable-next-line
        const name = value['_props'].uciSection['.name']
        this.remoteNetworkIp = value.form[name + '_' + 'remote_ip']
        this.remoteNetworkMask = value.form[name + '_' + 'remote_netmask']
      }, 1000)
    },
    addDefaultGlobalValues (name, role, sid) {
      this.$uci.set('openvpn', sid, 'type', role)
      this.$uci.set('openvpn', sid, '_name', name)
      this.$uci.set('openvpn', sid, '_auth', 'tls')
      this.$uci.set('openvpn', sid, 'enable', '0')
      this.$uci.set('openvpn', sid, 'keepalive', '10 120')
      this.$uci.set('openvpn', sid, 'port', '1194')
      this.$uci.set('openvpn', sid, 'persist_key', '1')
      this.$uci.set('openvpn', sid, 'verb', '5')
      this.$uci.set('openvpn', sid, 'proto', 'udp')
      this.$uci.set('openvpn', sid, 'cipher', 'BF-CBC')
    },
    addDefaultClientValues (name, role, sid) {
      // DEFAULT AUTH TLS OPTION
      this.$uci.set('openvpn', sid, '_tls_cipher', 'all')
      this.$uci.set('openvpn', sid, '_tls_auth', 'none')
      this.$uci.set('openvpn', sid, 'nobind', '1')
      this.$uci.set('openvpn', sid, 'auth', 'sha1')
      this.$uci.set('openvpn', sid, 'persist_tun', '1')
      this.$uci.set('openvpn', sid, 'dev', 'tun_c_' + name)
      this.$uci.set('openvpn', sid, 'client', '1')
      this.$uci.set('openvpn', sid, 'resolv_retry', 'infinite')
    },
    addDefaultServerValues (name, role, sid) {
      // DEFAULT AUTH TLS OPTION
      this.$uci.set('openvpn', sid, '_tls_cipher', 'all')
      this.$uci.set('openvpn', sid, '_tls_auth', 'none')
      this.$uci.set('openvpn', sid, 'auth', 'sha1')
      this.$uci.set('openvpn', sid, 'persist_tun', '1')
      this.$uci.set('openvpn', sid, 'dev', 'tun_s_' + name)
      this.$uci.set('openvpn', sid, 'tls_server', '1')
      this.$uci.set('openvpn', sid, 'upload_files', '0')
    },
    addClient (name, role) {
      const sid = name + '_client'
      const currentSectionNames = this.sections.map(s => s['.name'])
      if (currentSectionNames.includes(sid) === true) {
        this.$message.info(`Instance ${name} already exists`)
        return
      } else {
        this.$spin()
        this.$uci.add('openvpn', 'openvpn', sid)
        this.$uci.save().then(() => {
          this.$uci.apply().then(() => {
            this.$spin(false)
          })
        })
        this.addDefaultGlobalValues(name, role, sid)
        this.addDefaultClientValues(name, role, sid)
        this.$uci.save()
        this.$uci.apply()
        this.latestSection = sid
        this.beforeAddEdit(name, this.latestSection, role)
      }
      this.clearCreateInstanceForm()
    },
    addServer (name, role) {
      const sid = name + '_server'
      const currentSectionNames = this.sections.map(s => s.type)
      if (currentSectionNames.includes('server') === true) {
        this.$message.info('There can only be a single server instance')
        return
      } else {
        this.$spin()
        this.$uci.add('openvpn', 'openvpn', sid)
        this.$uci.save().then(() => {
          this.$uci.apply().then(() => {
            this.$spin(false)
          })
        })
        this.addDefaultGlobalValues(name, role, sid)
        this.addDefaultServerValues(name, role, sid)
        this.$uci.save()
        this.$uci.apply()
        this.latestSection = sid
        this.beforeAddEdit(name, this.latestSection, role)
      }

      this.clearCreateInstanceForm()
    },
    add (name, role) {
      if (role === 'client') {
        this.addClient(name, role)
      } else if (role === 'server') {
        this.addServer(name, role)
      }
    },
    edit (sectionName, type) {
      this.editorSection = sectionName
      this.editorType = type
      if (this.editorSection !== '') {
        this.editModal = true
      }
    },
    clearCreateInstanceForm () {
      this.formInline.name = ''
      this.formInline.role = ''
    },
    beforeAddEdit (name, latestSection, role) {
      const currentSectionNames = this.sections.map(s => s['.name'])
      if (currentSectionNames.includes(name + '_client') === false || currentSectionNames.includes(name + '_server') === false) {
        this.editorType = role
        this.edit(latestSection, role)
      }
    },
    setStatusName (fullInstanceName, instanceEnableValue) {
      let status = ''
      if (Object.prototype.hasOwnProperty.call(this.ubusData, fullInstanceName)) {
        if (instanceEnableValue === '1' && this.ubusData[fullInstanceName].running === true) {
          status = 'Active'
        } else if (instanceEnableValue === '1' && this.ubusData[fullInstanceName].running === false) {
          status = 'Inactive'
        } else if (instanceEnableValue === '0') {
          status = 'Disabled'
        }
      } else {
        if (instanceEnableValue === '0') {
          status = 'Disabled'
        }
      }
      return status
    },
    actionEnable (name) {
      // eslint-disable-next-line
      const specificSection = this.sections.filter(s => s['.name'] === name)
      if (Object.prototype.hasOwnProperty.call(specificSection[0], 'enable') === false || specificSection[0].enable === '0') {
        this.$spin()
        this.$uci.set('openvpn', name, 'enable', '1')
        this.$uci.save().then(() => {
          this.$uci.apply().then(() => {
            this.$spin(false)
          })
        })
      }
    },
    actionDisable (name) {
      // eslint-disable-next-line
      const specificSection = this.sections.filter(s => s['.name'] === name )
      if (Object.prototype.hasOwnProperty.call(specificSection[0], 'enable') === true && specificSection[0].enable === '1') {
        this.$spin()
        this.$uci.set('openvpn', name, 'enable', '0')
        this.$uci.save().then(() => {
          this.$uci.apply().then(() => {
            this.$spin(false)
          })
        })
      }
    },
    async load () {
      await this.$uci.load('openvpn')
      this.sections = this.$uci.sections('openvpn', 'openvpn')
    },
    ip2num (ip) {
      var d = ip.split('.')
      var num = 0
      num += Number(d[0]) * Math.pow(256, 3)
      num += Number(d[1]) * Math.pow(256, 2)
      num += Number(d[2]) * Math.pow(256, 1)
      num += Number(d[3])
      return num
    },
    isRemoteIpValid (remoteIp) {
      const lanIpInt = this.ip2num(this.networkLanIp)
      const lanMaskConverted = this.maskGetRemaining(this.networkLanMask) - 1
      const remoteIpInt = this.ip2num(remoteIp)

      if (remoteIpInt >= lanIpInt && remoteIpInt <= (lanIpInt + lanMaskConverted)) {
        return `IP address ${remoteIp} must not fall within the local network's range`
      }
    },
    getServiceList () {
      this.$rpc.call('ubus', 'call', { object: 'service', method: 'list' }).then(r => {
        this.ubusData = r.openvpn.instances
      })
    },
    ip2longInt (ip) {
      var components
      // eslint-disable-next-line
      if (components = ip.match(/^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/)) {
        var iplong = 0
        var power = 1
        for (var i = 4; i >= 1; i -= 1) {
          iplong += power * parseInt(components[i])
          power *= 256
        }
        return iplong
      } else {
        return -1
      }
    },
    maskGetRemaining (ip) {
      // eslint-disable-next-line
      var ip = ip.match(/^(\d+)\.(\d+)\.(\d+)\.(\d+)$/)
      if (ip) {
        return Math.abs((+ip[1] << 24) + (+ip[2] << 16) + (+ip[3] << 8) + (+ip[4]))
      }
    },
    getIpRangeFromAddressAndNetmask (ip, netmask) {
      var ipaddress = ip.split('.')
      var netmaskblocks = ['0', '0', '0', '0']
      if (!/\d+\.\d+\.\d+\.\d+/.test(netmask)) {
        netmaskblocks = ('1'.repeat(parseInt(netmask, 10)) + '0'.repeat(32 - parseInt(netmask, 10))).match(/.{1,8}/g)
        netmaskblocks = netmaskblocks.map(function (el) {
          return parseInt(el, 2)
        })
      } else {
        netmaskblocks = netmask.split('.').map(function (el) {
          return parseInt(el, 10)
        })
      }
      var invertedNetmaskBlocks = netmaskblocks.map(function (el) {
        return el ^ 255
      })
      var baseAddress = ipaddress.map(function (block, idx) {
        return block & netmaskblocks[idx]
      })
      var broadcastAddress = ipaddress.map(function (block, idx) {
        return block | invertedNetmaskBlocks[idx]
      })

      this.compRemoteFirstIp = baseAddress.join('.')
      this.compRemoteLastIp = broadcastAddress.join('.')
    },
    adjustOptions () {
      setTimeout(() => {
        const currentSection = this.sections.filter(s => {
          return s['.name'] === this.editorSection
        })
        this.$rpc.call('openvpn', 'get_section_values', { section: this.editorSection }).then((currentSectionLatestOptions) => {
          if (currentSection[0].type === 'client') {
            this.adjustClientOptions(currentSection, currentSectionLatestOptions)
          } else if (currentSection[0].type === 'server') {
            this.adjustServerOptions(currentSection, currentSectionLatestOptions)
          }
        }).catch((error) => {
          console.log(error)
        })
      }, 1000)
    },
    adjustClientOptions (currentSectionShownOnUI, currentSectionLatestOptions) {
      // eslint-disable-next-line
      if (currentSectionShownOnUI[0]['_auth'] === 'skey' && this.areDefaultClientTlsValuesFound(currentSectionLatestOptions)) {
        if (this.areTlsUploadsFoundClient(currentSectionLatestOptions)) {
          this.$rpc.call('file', 'remove', { path: currentSectionLatestOptions.ca })
          this.$rpc.call('file', 'remove', { path: currentSectionLatestOptions.key })
          this.$rpc.call('file', 'remove', { path: currentSectionLatestOptions.cert })
        }
        this.$rpc.call('openvpn', 'del_client_tls_values', { section: this.editorSection })
      // eslint-disable-next-line
      } else if (currentSectionShownOnUI[0]['_auth'] === 'tls' && this.areSkeyUploadsFound(currentSectionLatestOptions)) {
        this.$rpc.call('file', 'remove', { path: currentSectionLatestOptions.secret })
        this.$rpc.call('openvpn', 'del_client_skey_values', { section: this.editorSection })
        if (!this.areDefaultClientTlsValuesFound(currentSectionLatestOptions)) {
          this.$rpc.call('openvpn', 'add_client_default_tls_values', { section: this.editorSection })
        }
      }
    },
    adjustServerOptions (currentSectionShownOnUI, currentSectionLatestOptions) {
      // eslint-disable-next-line
      if (currentSectionShownOnUI[0]['_auth'] === 'skey' && this.areTlsUploadsFoundServer(currentSectionLatestOptions) && this.areDefaultServerTlsValuesFound(currentSectionLatestOptions)) {
        this.$rpc.call('file', 'remove', { path: currentSectionLatestOptions.ca })
        this.$rpc.call('file', 'remove', { path: currentSectionLatestOptions.key })
        this.$rpc.call('file', 'remove', { path: currentSectionLatestOptions.cert })
        this.$rpc.call('file', 'remove', { path: currentSectionLatestOptions.dh })
        this.$rpc.call('openvpn', 'del_server_tls_values', { section: this.editorSection })
      // eslint-disable-next-line
      } else if (currentSectionShownOnUI[0]['_auth'] === 'tls' && this.areSkeyUploadsFound(currentSectionLatestOptions) && !this.areDefaultServerTlsValuesFound(currentSectionLatestOptions)) {
        this.$rpc.call('file', 'remove', { path: currentSectionLatestOptions.secret })
        this.$rpc.call('openvpn', 'del_server_skey_values', { section: this.editorSection })
        this.$rpc.call('openvpn', 'add_server_default_tls_values', { section: this.editorSection })
      }
    },
    areTlsUploadsFoundClient (sectionAllOptions) {
      if (!Object.prototype.hasOwnProperty.call(sectionAllOptions, 'ca') && !Object.prototype.hasOwnProperty.call(sectionAllOptions, 'key') && !Object.prototype.hasOwnProperty.call(sectionAllOptions, 'cert')) {
        return false
      } else {
        return true
      }
    },
    areTlsUploadsFoundServer (sectionAllOptions) {
      if (!Object.prototype.hasOwnProperty.call(sectionAllOptions, 'ca') && !Object.prototype.hasOwnProperty.call(sectionAllOptions, 'key') && !Object.prototype.hasOwnProperty.call(sectionAllOptions, 'cert') && !Object.prototype.hasOwnProperty.call(sectionAllOptions, 'dh')) {
        return false
      } else {
        return true
      }
    },
    areSkeyUploadsFound (sectionAllOptions) {
      if (!Object.prototype.hasOwnProperty.call(sectionAllOptions, 'secret')) {
        return false
      } else {
        return true
      }
    },
    areDefaultServerTlsValuesFound (sectionAllOptions) {
      if (!Object.prototype.hasOwnProperty.call(sectionAllOptions, '_tls_cipher') && !Object.prototype.hasOwnProperty.call(sectionAllOptions, '_tls_auth') && !Object.prototype.hasOwnProperty.call(sectionAllOptions, 'tls_server') && !Object.prototype.hasOwnProperty.call(sectionAllOptions, 'auth')) {
        return false
      } else {
        return true
      }
    },
    areDefaultClientTlsValuesFound (sectionAllOptions) {
      if (!Object.prototype.hasOwnProperty.call(sectionAllOptions, '_tls_cipher') && !Object.prototype.hasOwnProperty.call(sectionAllOptions, 'client') && !Object.prototype.hasOwnProperty.call(sectionAllOptions, 'auth')) {
        return false
      } else {
        return true
      }
    }
  },
  computed: {
    modalTitle () {
      return `Configure ${this.editorSection}`
    },
    uploadedFileWithSectionName () {
      return 'cbid.openvpn.' + this.editorSection + '.' + this.uploadedFileName
    }
  },
  created () {
    this.load()
    this.getLanNetwork()
    this.getServiceList()
  }

}

</script>

<style>

</style>
