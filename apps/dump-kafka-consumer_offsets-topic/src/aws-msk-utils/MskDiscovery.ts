import { 
  KafkaClient, 
  GetBootstrapBrokersCommand, 
  ListClustersV2Command,
  ListClustersV2CommandOutput, // Importato tipo esplicito
  Cluster // Importato tipo esplicito per l'iterazione
} from "@aws-sdk/client-kafka";

export class MskDiscovery {
  private client: KafkaClient;

  constructor(region: string) {
    this.client = new KafkaClient({ region });
  }

  /**
   * Restituisce una lista di cluster disponibili (Nome e ARN).
   */
  async listAvailableClusters(): Promise<{ name: string; arn: string }[]> {
    const command = new ListClustersV2Command({});
    const response: ListClustersV2CommandOutput = await this.client.send(command);
    
    if (!response.ClusterInfoList) return [];

    return response.ClusterInfoList.map((c: Cluster) => ({
      name: c.ClusterName || "Sconosciuto",
      arn: c.ClusterArn || ""
    }));
  }

  /**
   * Cerca un cluster per nome e restituisce il suo ARN.
   * Gestisce la paginazione AWS se ci sono molti cluster.
   */
  async getArnByClusterName(clusterName: string): Promise<string> {
    let nextToken: string | undefined = undefined;

    do {
      const command = new ListClustersV2Command({ NextToken: nextToken });
      
      // FIX: Tipizzazione esplicita della risposta
      const response: ListClustersV2CommandOutput = await this.client.send(command);

      // FIX: Tipizzazione esplicita dell'elemento 'c' nella callback find
      const found = response.ClusterInfoList?.find((c: Cluster) => c.ClusterName === clusterName);
      
      if (found && found.ClusterArn) {
        console.log(`[AWS API] Trovato cluster '${clusterName}': ${found.ClusterArn}`);
        return found.ClusterArn;
      }

      nextToken = response.NextToken;
    } while (nextToken);

    throw new Error(`Cluster con nome '${clusterName}' non trovato nella regione specificata.`);
  }

  /**
   * Recupera la stringa di connessione SASL/IAM usando l'ARN.
   */
  async getIamBootstrapBrokers(clusterArn: string): Promise<string> {
    try {
      const command = new GetBootstrapBrokersCommand({ ClusterArn: clusterArn });
      const response = await this.client.send(command);

      if (!response.BootstrapBrokerStringSaslIam) {
        throw new Error("Nessuna stringa di bootstrap SASL IAM trovata per questo cluster. Verifica che IAM sia abilitato.");
      }

      console.log(`[AWS API] Broker recuperati: ${response.BootstrapBrokerStringSaslIam}`);
      return response.BootstrapBrokerStringSaslIam;
    } catch (error) {
      console.error("Errore nel recupero dei broker MSK:", error);
      throw error;
    }
  }
}
