{%- from 'prometheus/map.jinja' import prometheus with context %}

prom_user:
  user.present:
    - name: prometheus

m2crypto:
  pkg.installed

{{ prometheus.base_dir }}:
  file.directory:
    - user: root
    - group: root
    - mode: 755

{{ prometheus.base_dir }}/prom.crt:
  x509.certificate_managed:
    - user: root
    - group: root
    - mode: 644
    - CN: {{ grains['id'] }}
    - subjectAltName: DNS:{{ grains['id'] }}
    - backup: True
    - ca_server: {{ prometheus.ca_server }}
    - signing_policy: prometheus
    - managed_private_key:
        name: {{ prometheus.base_dir }}/prom.key
        bits: 4096
        backup: True
        user: root
        group: prometheus
        mode: 640
    # https://github.com/saltstack/salt/issues/52167
    - unless: 
#      - '[ -f  {{ prometheus.base_dir }}/prom.crt ]'
      - 'enddate=$(date -d "$(openssl x509 -in {{ prometheus.base_dir }}/prom.crt -enddate -noout | cut -d= -f2)" +%s) ; now=$(date +%s) ; now=$(( now + 432000)); [ $enddate -gt $now ]'

{{ prometheus.base_dir }}/prom-ca.crt:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents_pillar: prometheus:ca
