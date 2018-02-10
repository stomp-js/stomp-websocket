FROM rabbitmq:3.7.3-alpine

run rabbitmq-plugins enable --offline rabbitmq_web_stomp

EXPOSE 15674
