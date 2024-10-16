# syntax=docker/dockerfile:1

# run
FROM mcr.microsoft.com/openjdk/jdk:17-distroless

COPY ./target/spring-petclinic-langchain4j-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

# Run the jar file
ENTRYPOINT ["java", "-Djava.security.egd=file:/dev/./urandom", "-jar", "/app.jar"]
