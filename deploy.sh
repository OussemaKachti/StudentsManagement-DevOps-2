#!/bin/bash
set -e

echo "=== 1. NETTOYAGE COMPLET ==="
kubectl delete deployment mysql students-management -n devops 2>/dev/null || true
kubectl delete service mysql-service students-service -n devops 2>/dev/null || true
kubectl delete pvc mysql-pvc -n devops 2>/dev/null || true
kubectl delete pv mysql-pv 2>/dev/null || true

echo "=== 2. Attente suppression PVC... ==="
sleep 10

echo "=== 3. Nettoyage disque ==="
sudo rm -rf /mnt/data/mysql
sudo mkdir -p /mnt/data/mysql
sudo chmod 777 /mnt/data/mysql

echo "=== 4. Création PV et PVC ==="
kubectl apply -f k8s/mysql-pv.yaml
sleep 3
kubectl apply -f k8s/mysql-pvc.yaml
sleep 5

echo "=== 5. Vérification PVC ==="
kubectl get pvc -n devops

echo "=== 6. Déploiement MySQL ==="
kubectl apply -f k8s/mysql-deployment.yaml
kubectl apply -f k8s/mysql-service.yaml

echo "=== 7. Attente MySQL (90 secondes) ==="
for i in {1..90}; do
    echo -n "."
    sleep 1
done
echo ""

echo "=== 8. Vérification pods ==="
kubectl get pods -n devops

echo "=== 9. Test connexion MySQL ==="
kubectl exec -it deployment/mysql -n devops -- bash -c "mysql -uroot -proot -e 'SHOW DATABASES; CREATE DATABASE IF NOT EXISTS StudentsManagement;'"

echo "=== 10. Déploiement Spring Boot ==="
kubectl apply -f k8s/spring-deployment.yaml
kubectl apply -f k8s/spring-service.yaml

echo "=== 11. Attente Spring Boot (60 secondes) ==="
for i in {1..60}; do
    echo -n "."
    sleep 1
done
echo ""

echo "=== 12. État final ==="
kubectl get pods -n devops
kubectl get svc -n devops

echo "=== 13. Test application ==="
sleep 5
curl http://localhost:30089/actuator/health

echo ""
echo "=== TERMINÉ! ==="