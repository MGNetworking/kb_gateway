# Étape 1 : build de l'application
FROM maven:3.8.7-eclipse-temurin-17 AS build
WORKDIR /app
COPY pom.xml .
COPY src ./src
RUN mvn clean package -DskipTests

# Étape 2 : création de l'image runtime
FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=build /app/target/gateway.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java","-jar","app.jar"]
