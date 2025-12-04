FROM eclipse-temurin:17-jdk-alpine

# On ajoute un volume pour les fichiers temporaires
VOLUME /tmp

# On copie le fichier .jar généré par Maven vers l'image sous le nom app.jar
COPY target/*.jar app.jar

# La commande pour lancer l'application
ENTRYPOINT ["java","-jar","/app.jar"]