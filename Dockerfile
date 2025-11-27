# Utiliser une image Eclipse Temurin (recommandée pour Java 17)
FROM eclipse-temurin:17-jdk-alpine

# Ajouter un volume pour les fichiers temporaires
VOLUME /tmp

# Argument pour le JAR file
ARG JAR_FILE=target/*.jar

# Copier le JAR dans le conteneur
COPY ${JAR_FILE} app.jar

# Point d'entrée pour lancer l'application
ENTRYPOINT ["java","-jar","/app.jar"]