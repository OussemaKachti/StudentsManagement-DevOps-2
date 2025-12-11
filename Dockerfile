# Stage 1: Build avec Maven
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

# Copier les fichiers Maven wrapper et pom.xml
COPY pom.xml .
COPY .mvn .mvn
COPY mvnw .
COPY mvnw.cmd .

# Télécharger les dépendances Maven (pour optimiser le cache Docker)
RUN mvn dependency:go-offline -B || true

# Copier le code source
COPY src ./src

# Build l'application avec Maven (génère le JAR exécutable)
RUN mvn clean package -DskipTests -B

# Stage 2: Runtime avec JRE léger
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Créer un volume pour les fichiers temporaires
VOLUME /tmp

# Copier le JAR depuis le stage de build
COPY --from=build /app/target/*.jar app.jar

# Exposer le port 8080
EXPOSE 8080

# Configuration JVM optimisée
ENV JAVA_OPTS="-Xmx512m -Xms256m"

# Commande pour démarrer l'application
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]