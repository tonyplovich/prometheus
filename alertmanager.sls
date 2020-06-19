{%- from 'prometheus/map.jinja' import prometheus with context %}

include:
  - prometheus

{{ prometheus.base_dir }}/alertmanager_data:
  file.directory:
    - user: prometheus
    - group: prometheus
    - dir_mode: 755

{%- if prometheus.pkg_install %}
prometheus-alertmanager:
  pkg.installed
{%- else %}
alertmanager:
  archive.extracted:
    - name: {{ prometheus.base_dir }}
    - user: root
    - group: root
    - source: {{ prometheus.alertmanager.url }}
    - source_hash: {{ prometheus.alertmanager.hashfile_url }}
{%- endif %}

{{ prometheus.base_dir }}/alertmanager:
  file.symlink:
    - target: {{ prometheus.base_dir }}/{{ prometheus.alertmanager.archive_name }}
    - require:
      - archive: alertmanager

/etc/systemd/system/alertmanager.service:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - context:
        options: {{ prometheus.alertmanager.options }}
        base_dir: {{ prometheus.base_dir }}
    - source: salt://prometheus/files/systemd/alertmanager.service.jinja
    - watch_in:
      - service: alertmanager_service

{{ prometheus.base_dir }}/alertmanager/config.yml:
  file.managed:
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - source: salt://prometheus/files/config.yml.jinja
    - context:
        config: {{ prometheus.alertmanager.config }}
    - watch_in:
      - service: alertmanager_service

alertmanager_service:
  service.running:
    - name: alertmanager
    - enable: True
