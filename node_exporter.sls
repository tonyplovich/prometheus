{%- from 'prometheus/map.jinja' import prometheus with context %}

include:
  - prometheus

{%- if prometheus.pkg_install %}
prometheus-node_exporter:
  pkg.installed
{%- else %}
node_exporter:
  archive.extracted:
    - name: {{ prometheus.base_dir }}
    - user: root
    - group: root
    - source: {{ prometheus.node_exporter.url }}
    - source_hash: {{ prometheus.node_exporter.hashfile_url }}
{%- endif %}

{{ prometheus.base_dir }}/node_exporter:
  file.symlink:
    - target: {{ prometheus.base_dir }}/{{ prometheus.node_exporter.archive_name }}
    - require:
      - archive: node_exporter

/etc/systemd/system/node_exporter.service:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - source: salt://prometheus/files/systemd/node_exporter.service.jinja
    - template: jinja
    - context:
        options: {{ prometheus.node_exporter.options }}
        base_dir: {{ prometheus.base_dir }}
    - watch_in:
      - service: node_exporter_service

{{ prometheus.base_dir }}/node_exporter/web_config.yml:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source: salt://prometheus/files/config.yml.jinja
    - context:
        config: {{ prometheus.node_exporter.web_config }}
        base_dir: {{ prometheus.base_dir }}
    - watch_in:
      - service: node_exporter_service

node_exporter_service:
  service.running:
    - name: node_exporter
    - enable: True

{%- if grains['id'] not in salt['mine.get']('*', 'node_exporter') %}
mine_node_exporter:
  module.run:
    - mine.update: []
{%- endif %}
