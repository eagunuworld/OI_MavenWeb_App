FROM tomcat:8.0.20-jre8
RUN sed -i '/<\/tomcat-users>/ i\<user username="admin" password="passw0rd" roles="admin-gui,manager-gui"/>' /usr/local/tomcat/conf/tomcat-users.xml
COPY target/healthz-app*.war /usr/local/tomcat/webapps/healthz-app.war
