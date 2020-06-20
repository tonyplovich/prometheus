# Prometheus
Configure [Prometheus](https://prometheus.io/docs/introduction/overview/) servers and exporters via Saltstack.
## Usage
**Note:** Some of the default configuration is in map.jinja and the systemd service files.  These are configuration settings that rely on the structure of the formula.
### Generate CA certs
The formula uses Salt's x509 states to setup TLS between the node_exporters and the Prom server.
* Create a CA cert/key pair on the Salt master
* Update the minion config on the master:
** /etc/salt/minion.d/signing_policy.conf
```
x509_signing_policies:
  prometheus:
    - signing_cert: /root/ca.crt
    - signing_private_key: /root/ca.key
    - signing_private_key_passphrase: letmein
    - C: US
    - ST: Illinios
    - basicConstraints: "critical CA:false"
    - keyUsage: "critical keyEncipherment"
    - subjectKeyIdentifier: hash
    - authorityKeyIdentifier: keyid,issuer:always
#    - copypath: /root/issued_certs/
    - days_valid: 365
```
* Update the master's config to allow signing:
  * /etc/salt/master
```
peer:
  .*:
    - x509.sign_remote_certificate
```
### Salt API Node Discovery
The formula provides a modist Python script to manage node_exporter targets via [Prometheus' file service discovery](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#file_sd_config).  By default, the script will add targets for each minion that has a mine entry for node_exporter.  When the minion's keys are removed, their mine data will be removed, and the corresponding Prometheus target will be removed next time the script runs.
* Install [Salt's API service](https://docs.saltstack.com/en/latest/ref/netapi/all/salt.netapi.rest_cherrypy.html#a-rest-api-for-salt).
* Update the Salt master's config:
```
external_auth:
  pam:
    SOMEUSER:
      - '@runner':
        - 'mine.get':
            args:
            - '\*'
            - 'node_exporter'
rest_cherrypy:
  port: 8000
  ssl_crt: /etc/pki/tls/certs/salt-api.pem.crt
  ssl_key: /etc/pki/tls/private/salt-api.pem.key
  log_access_file: /var/log/salt/api-access
  log_error_file: /var/log/salt/api-errror
  debug: True
```
* Create a local user on the Salt master
```
# useradd SOMEUSER
# passwd SOMEUSER
```
* Assign prometheus.salt_api_sd to the Prom server
* Add pillar config:
```
mine_functions:
  node_exporter:
    - mine_function: test.echo
    - True

prometheus:
  salt_api_sd:
    user: SOMEUSER
    pass: SOMEPASS
    
```
* Update minion config to allow newer form of module state
```
use_superseded:
  - module.run
```
### Custom Metrics via Textfile Collectors
[Textfile collectors](https://github.com/prometheus/node_exporter#textfile-collector) provide an easy way to get metrics into Prometheus: just drop them in a file and the node_exporter will make them available to Prometheus.  A simple approach to this is with a custom script and a cronjob / systemd timer.
* Add your script to files/textfile_collector_scripts/
* Add an SLS that drops the script and a cron to run it in
  * textfile_collectors/yum.sls provides an example of this
  * **Note:** it's important for the script to write all its output to the textfile instantly.  If not, prometheus may be scrapping while the file is being updated, which could cause errors.
    * Utilities like sponge, or mv, can be used to accomplish this.
### server.sls
* <https://prometheus.io/docs/prometheus/latest/configuration/configuration/>
* The Prometheus server doesn't provide TLS.  Stick it behind a proxy if you need authentication / TLS.
* Assign sls to the minion(s) that'll be your Prometheus server.
* Open firewall ports.
  * 9090/tcp - Prometheus web console
* Add the config to pillar.
```
prometheus:
  server:
    # command line options for the prometheus binary, appended to systemd service
    options: |
        --log.level=info

    # This is dumped directly into the server's config file
    config:
      alerting:
        alertmanagers:
          - static_configs:
            - targets:
              - YOUR_ALERTMANGER_HERE:9093
              - YOUR_ALERTMANGER_HERE:9093
              - YOUR_ALERTMANGER_HERE:9093
      scrape_configs:

        # snmp_exporter config
        - job_name: snmp
          static_configs:
            - targets:
              - SOME_SNMP_TARGET REPLACE_ME
          metrics_path: /snmp
          params:
            module: [if_mib]
          relabel_configs:
            - source_labels: [__address__]
              target_label: __param_target
            - source_labels: [__param_target]
              target_label: instance
            - target_label: __address__
              # The SNMP exporter's real hostname:port.
              replacement: 127.0.0.1:9116

        # blackbox_exporter config
        - job_name: blackbox
          metrics_path: /probe
          params:
            module: [http_2xx]  # Look for a HTTP 200 response.
          static_configs:
            - targets:
              - EXAMPLE1.COM
              - EXAMPLE2.COM
              - EXAMPLE3.COM
          relabel_configs:
            - source_labels: [__address__]
              target_label: __param_target
            - source_labels: [__param_target]
              target_label: instance
            - target_label: __address__
              # The blackbox exporter's real hostname:port.
              replacement: 127.0.0.1:9115
```
### alertmanager.sls
* <https://prometheus.io/docs/alerting/latest/configuration/>
* The Alertmanager web console doesn't provide TLS.  Stick it behind a proxy if you need authentication / TLS.
* Open firewall ports:
  * 9093/tcp - Alertmanager API/ web console
  * 9094/tcp - Alertmanager clustering port
* Add the config to pillar.
```
prometheus:
  alertmanager:
    # command line options for the alertmanager binary, appended to systemd service
    options: |
        --log.level=info

    # This is dumped directly into the alertmanager's config file
    config:
      route:
      # your routes
      receivers:
      # your receivers
```
### node_exporter.sls
* <https://github.com/prometheus/node_exporter>
* Assign to whichever servers you want to monitor.
* Open firewall port:
  * 9100/tcp - node_exporter
* Most of the config you'll want to change will be adding / removing collectors.
```
prometheus:
  node_exporter:
    # command line options for the node_exporter binary, appended to systemd service
    options: |
        --log.level=info --no-collector.zfs
```
### blackbox_exporter.sls
* <https://github.com/prometheus/blackbox_exporter/>
* The blackbox_exporter doesn't provide TLS.  Stick it behind a proxy if you need authentication / TLS.
* Assign to whichever server will be running the blackbox exporter.
* Open firewall ports:
  * 9115/tcp 
* Add the config to pillar.
```
prometheus:
  blackbox_exporter:

    # command line options for the blackbox_exporter binary, appended to systemd service
    options: |
        --log.level=info

    # This is dumped directly into the exporter's config file
    config:
      modules:
        http_2xx:
          prober: http
          timeout: 5s
          http:
            valid_http_versions: ["HTTP/1.1", "HTTP/2"]
            valid_status_codes: []  # Defaults to 2xx
            method: GET
            no_follow_redirects: false
            tls_config:
              insecure_skip_verify: false
            preferred_ip_protocol: "ip4" # defaults to "ip6"
```
### snmp_exporter.sls
* <https://github.com/prometheus/snmp_exporter/>
* The snmp_exporter doesn't provide TLS.  Stick it behind a proxy if you need authentication / TLS.
* Assign to whichever server will be running the snmp exporter.
* Open firewall port:
  * 9116/tcp - snmp_exporter
* Generate your snmp.yml (per above docs) and add to /files
  * snmp.yml is huge, so it's dropped from the formula as a static file.
* Add the config to pillar.
```
prometheus:
  snmp_exporter:
    # command line options for the snmp_exporter binary, appended to systemd service
    options: |
        --log.level=info
```
