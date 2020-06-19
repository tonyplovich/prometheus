{%- from 'prometheus/map.jinja' import prometheus with context %}

include:
  - prometheus

{{ prometheus.base_dir }}/prom-server.crt:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - contents_pillar: prometheus:server:crt

{{ prometheus.base_dir }}/prom-server.key:
  file.managed:
    - user: root
    - group: prometheus
    - mode: 440
    - contents_pillar: prometheus:server:key

{%- if prometheus.pkg_install %}
prometheus-server:
  pkg.installed
{%- else %}
prometheus:
  archive.extracted:
    - name: {{ prometheus.base_dir }}
    - user: root
    - group: root
    - source: {{ prometheus.server.url }}
    - source_hash: {{ prometheus.server.hashfile_url }}
{%- endif %}

{{ prometheus.base_dir }}/prometheus:
  file.symlink:
    - target: {{ prometheus.base_dir }}/{{ prometheus.server.archive_name }}
    - require:
      - archive: prometheus

{{ prometheus.data_dir }}:
  file.directory:
    - user: prometheus
    - group: prometheus
    - dir_mode: 755

/etc/systemd/system/prometheus.service:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - source: salt://prometheus/files/systemd/prometheus.service.jinja
    - template: jinja
    - context:
        options: {{ prometheus.server.options }}
        base_dir: {{ prometheus.base_dir }}
        listen_address: {{ prometheus.server.listen_address }}
        port: {{ prometheus.server.port }}
    - watch_in:
      - service: prometheus_service

{{ prometheus.base_dir }}/prometheus/config.yml:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - context:
        config: {{ prometheus.server.config }}
    - template: jinja
    - source: salt://prometheus/files/config.yml.jinja
    - watch_in:
      - service: prometheus_service

prometheus_service:
  service.running:
    - name: prometheus
    - enable: True
