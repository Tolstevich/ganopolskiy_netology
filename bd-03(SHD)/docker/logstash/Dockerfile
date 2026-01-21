FROM docker.elastic.co/logstash/logstash:7.17.9

COPY ./config/logstash.yml /usr/share/logstash/config/
COPY ./pipeline/ /usr/share/logstash/pipeline/

USER root
RUN chown -R logstash:logstash /usr/share/logstash/config
RUN chown -R logstash:logstash /usr/share/logstash/pipeline
USER logstash

CMD ["logstash", "-f", "/usr/share/logstash/pipeline"]