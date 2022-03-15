<template>
  <vuci-form-item-template v-bind="VuciFormItemTemplateProps">
    <a-upload
      action="/upload"
      :data="{path: this.uploadedFileName}"
      :multiple="true"
      :beforeUpload="getName"
      @change="comboHandleAndSave"
      :file-list="fileList"
      v-model="model"
    >
      <a-button> <a-icon type="upload" />
        <span>
          Upload
        </span>
      </a-button>
    </a-upload>
    <span v-if="this.isFileFound">{{foundFileDirectory}}</span>
    <span v-if="this.isFileFound === false && this.foundFileDirectory === ''">No file found</span>
  </vuci-form-item-template>
</template>

<script>
import VuciFormItemMixin from './VuciFormItemMixin'
// this.$rpc.call('file', 'remove', { path: '/tmp/firmware.bin' })
// /etc/vuci-uploads/

// cbid.openvpn.<named-section-name>.caca.cert.pem
// cbid.openvpn.<named-section-name>.certclient.cert.pem
// cbid.openvpn.<named-section-name>.keyclient.key.pem
export default {
  name: 'VuciFormUpload',
  mixins: [VuciFormItemMixin],
  props: {
    name: String,
    uciSection: Object,
    sectionNaming: String
  },
  data () {
    return {
      fileNameWithoutAdditions: '',
      uploadedFileName: '',
      foundFileDirectory: '',
      fileList: [],
      isFileFound: false
    }
  },
  timers: {
    isFile: { time: 1500, autostart: true, immediate: true, repeat: true }
  },
  methods: {
    isFileFoundInSection (section, nameOfUploadedOption) {
      if (!Object.prototype.hasOwnProperty.call(section, nameOfUploadedOption) || section.nameOfUploadedOption === '') {
        return false
      } else {
        return true
      }
    },
    isFile () {
      this.$rpc.call('test', 'get_section_values', { section: this.uciSection['.name'] }).then((section) => {
        if (!this.isFileFoundInSection(section, this.name)) {
          this.isFileFound = false
          this.foundFileDirectory = ''
        } else {
          this.isFileFound = true
          this.foundFileDirectory = section[this.name].replace('/etc/vuci-uploads/', '')
        }
      })
    },
    comboHandleAndSave (info) {
      this.handleChange(info)
      this.__saveTest()
    },
    handleChange (info) {
      var fileList = [...info.fileList]
      fileList = fileList.slice(-1)
      console.log(info.fileList)
      console.log(info)
      if (info.fileList.length <= 0) {
        console.log('length is 0')
        this.uploadedFileName = ''
      }
      this.fileList = fileList
    },
    onUploadArchive (info) {
      const file = info.file
      const status = file.status

      if (status === 'uploading' || status === 'removed') {
        info.fileList.length = 0
      }

      if (status !== 'done') {
        this.$message.error(`upload '${file.name}' failed.`)
      }
    },
    getFileName (file, fileList) {
      const fileName = file.name
      const pathUrl = '/etc/vuci-uploads/'
      this.uploadedFileName = pathUrl + this.sectionNaming + fileName
      console.log(this.uploadedFileName)
      console.log('file name without anything ' + fileName)
      console.log('list of files ' + fileList)
    },
    getName (file) {
      return new Promise(resolve => {
        this.getFileName(file)
        this.fileNameWithoutAdditions = file.name
        resolve()
      })
    },
    __saveTest () {
      if (this.uploadedFileName !== '') {
        this.$uci.set(this.config, this.sid, this.name, this.uploadedFileName)
        console.log('set uploaded file name')
      } else {
        // this.$uci.set(this.config, this.sid, this.name, '')
        console.log('file not found')
      }
    }
  },
  created () {
    this.isFile()
  }
}
</script>

<style>

</style>
