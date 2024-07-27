const express = require('express');
const bodyParser = require('body-parser');
const k8s = require('@kubernetes/client-node');

const app = express();
const port = 3000;

// Configuração do Kubernetes Client
const kc = new k8s.KubeConfig();
kc.loadFromDefault();

const k8sApi = kc.makeApiClient(k8s.AppsV1Api);

app.use(bodyParser.json());
app.use(express.static('public'));

// Rota para escalar o deployment
app.post('/scale', async (req, res) => {
  const { namespace, deploymentName, replicas, cpu } = req.body;

  console.log(`Recebido pedido para escalar ${deploymentName} no namespace ${namespace} para ${replicas} réplicas e ${cpu} CPUs`);

  try {
    // Verifique se o deployment existe
    const { body: deployment } = await k8sApi.readNamespacedDeployment(deploymentName, namespace);
    console.log('Deployment encontrado:', deployment);

    // Atualize o número de réplicas
    deployment.spec.replicas = parseInt(replicas, 10);

    // Verifique e formate o campo de requisições de recursos
    if (!deployment.spec.template.spec.containers[0].resources) {
      deployment.spec.template.spec.containers[0].resources = {};
    }
    deployment.spec.template.spec.containers[0].resources.requests = {
      cpu: `${cpu}`
    };

    // Remova campos desnecessários
    delete deployment.metadata.creationTimestamp;
    delete deployment.metadata.deletionTimestamp;
    delete deployment.metadata.generation;
    delete deployment.metadata.resourceVersion;
    delete deployment.metadata.selfLink;
    delete deployment.metadata.uid;
    delete deployment.spec.template.metadata.creationTimestamp;

    if (deployment.status && deployment.status.conditions) {
      deployment.status.conditions.forEach(condition => {
        delete condition.lastTransitionTime;
        delete condition.lastUpdateTime;
      });
    }

    const updatedDeployment = await k8sApi.replaceNamespacedDeployment(deploymentName, namespace, deployment);
    console.log('Deployment atualizado:', updatedDeployment);

    res.status(200).send({ message: `Deployment escalado para ${replicas} réplicas e ${cpu} CPUs.` });
  } catch (err) {
    console.error('Erro ao escalar o deployment:', err);
    res.status(500).send({ error: 'Falha ao escalar o deployment.', details: err.message });
  }
});

app.listen(port, () => {
  console.log(`Servidor rodando na porta ${port}`);
});
