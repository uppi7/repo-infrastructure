# IMAGE_PREFIX 由 docker-compose build args 注入
ARG IMAGE_PREFIX

FROM ${IMAGE_PREFIX}frontend_base:latest   AS frontend-base
FROM ${IMAGE_PREFIX}frontend_course:latest AS frontend-course

FROM nginx:1.27-alpine
RUN rm /etc/nginx/conf.d/default.conf
COPY nginx.conf /etc/nginx/nginx.conf
COPY --from=frontend-base   /dist /usr/share/nginx/html/base
COPY --from=frontend-course /dist /usr/share/nginx/html/course
EXPOSE 80
