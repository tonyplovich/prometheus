{%- from 'prometheus/map.jinja' import prometheus with context %}

include:
  - prometheus.textfile_collectors

{{ prometheus.base_dir }}/textfile_collector_scripts/yum.sh:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - source: salt://prometheus/files/textfile_collector_scripts/yum.sh

{{ prometheus.base_dir }}/textfile_collector_scripts/yum.sh > {{ prometheus.base_dir }}/textfiles/yum.$$ && mv {{ prometheus.base_dir }}/textfiles/yum.{$$,prom}:
  cron.present:
    - user: prometheus
    - minute: '*/1'
