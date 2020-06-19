{%- from 'prometheus/map.jinja' import prometheus with context %}

include:
  - prometheus

{%- if prometheus.pkg_install %}
prometheus-blackbox_exporter:
  pkg.installed
{%- else %}
blackbox_exporter:
  archive.extracted:
    - name: {{ prometheus.base_dir }}
    - user: root
    - group: root
    - source: {{ prometheus.blackbox_exporter.url }}
    - source_hash: {{ prometheus.blackbox_exporter.hashfile_url }}
{%- endif %}

{{ prometheus.base_dir }}/blackbox_exporter:
  file.symlink:
    - target: {{ prometheus.base_dir }}/{{ prometheus.blackbox_exporter.archive_name }}
    - require:
      - archive: blackbox_exporter

/etc/systemd/system/blackbox_exporter.service:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - source: salt://prometheus/files/systemd/blackbox_exporter.service.jinja
    - template: jinja
    - context:
        options: {{ prometheus.blackbox_exporter.options }}
        base_dir: {{ prometheus.base_dir }}
    - watch_in:
      - service: blackbox_exporter_service

{{ prometheus.base_dir }}/blackbox_exporter/config.yml:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source: salt://prometheus/files/config.yml.jinja
    - context:
        config: {{ prometheus.blackbox_exporter.config }}
    - watch_in:
      - service: blackbox_exporter_service

blackbox_exporter_service:
  service.running:
    - name: blackbox_exporter
    - enable: True
