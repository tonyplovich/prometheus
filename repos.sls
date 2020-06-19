# your repo should provide the following packages:
# prometheus-server
# prometheus-alertmanager
# prometheus-node_exporter
# prometheus-snmp_exporter
# prometheus-blackbox_exporter
# The file layout of the packages should mirror what the formula creates
prometheus:
  pkgrepo.managed:
    - baseurl: 
    - gpgcheck: 1
