{%- from 'prometheus/map.jinja' import prometheus with context %}

include:
  - prometheus

{%- if prometheus.pkg_install %}
prometheus-server:
  pkg.installed
{%- else %}
snmp_exporter:
  archive.extracted:
    - name: {{ prometheus.base_dir }}
    - user: root
    - group: root
    - source: {{ prometheus.snmp_exporter.url }}
    - source_hash: {{ prometheus.snmp_exporter.hashfile_url }}
{%- endif %}

{{ prometheus.base_dir }}/snmp_exporter:
  file.symlink:
    - target: {{ prometheus.base_dir}}/{{ prometheus.snmp_exporter.archive_name }}
    - require:
      - archive: snmp_exporter

/etc/systemd/system/snmp_exporter.service:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - source: salt://prometheus/files/systemd/snmp_exporter.service.jinja
    - template: jinja
    - context:
        options: {{ prometheus.snmp_exporter.options }}
        base_dir: {{ prometheus.base_dir }}
    - watch_in:
      - service: snmp_exporter_service

{{ prometheus.base_dir }}/snmp_exporter/snmp.yml:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - source: salt://prometheus/files/snmp.yml
    - watch_in:
      - service: snmp_exporter_service

snmp_exporter_service:
  service.running:
    - name: snmp_exporter
    - enable: True
