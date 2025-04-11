function karateConfig() {
    let env = karate.properties['env']; // get system property 'karate.env'
    karate.log('karate.env system property was:', env);
    let cmdHostUrl = karate.properties['host_url'];
    karate.log('hostUrl from command line :', cmdHostUrl);

    if (!env) {
        env = 'dev';
    }

    let config = {
        env: env,
        hostUrl: 'https://pay-gateway-eus2.gatewy-dev.kpsazc.dgtl.kroger.com',
        returnPath: '/payments/gateway/v1/purchases',
        tokenUrl: 'https://api-ce.kroger.com/v1/connect/oauth2/token',
        client_id: karate.properties['client_id'],
        client_secret: karate.properties['client_secret'],
        scope: 'urn:com:kroger:kr:payments:gateway:write',
        messageMaker_host: 'https://pay-msg-mkr-eus2.gatewy-dev.kpsazc.dgtl.kroger.com',
        messageMaker_Path: '/v1/kcp-payments/messages',

        key_deserializer: 'org.apache.kafka.common.serialization.StringDeserializer',
        value_deserializer: 'io.confluent.kafka.serializers.KafkaAvroDeserializer',
        user_info_credential: 'Ln0HYS8xHGuFWh3d:Xz+|4cKw$HZ$CPZ}',
        security_protocol: 'SASL_SSL',
        sasl_mechanism : 'OAUTHBEARER',
        JAAS_CONFIG_CONSUMER: 'org.apache.kafka.common.security.oauthbearer.OAuthBearerLoginModule required authUrl=\"https://login.microsoftonline.com/8331e14a-9134-4288-bf5a-5e2c8412f074\" appId=\"09dda2dc-48e6-4077-9e53-49b06d6c399e\" appSecret=\"umb8Q~5cqRZoMs8zlAZEdgAncLq.-lKtD42qFcLs\"',
        authentication_implmentation_class: 'com.kroger.streaming.ext.azure.oauth.EventHubsOAuthHandler',
        server: 'krogerCommercePlatform-dev.servicebus.windows.net:9093',
        registryurl: 'https://desp-schema-registry-nonprod.internal.kroger.com:8443/dev',
        groupNameSuffix: 'dev'
    }
    if (env == 'review') {
        config.hostUrl= 'https://pay-gateway-eus2.gatewy-review.kpsazc.dgtl.kroger.com';
        config.messageMaker_host= 'https://pay-msg-mkr-eus2.gatewy-review.kpsazc.dgtl.kroger.com'
    }
    if (env == 'test') {
        config.hostUrl= 'https://pay-gateway-eus2.gatewy-test.kpsazc.dgtl.kroger.com';
        config.messageMaker_host= 'https://pay-msg-mkr-eus2.gatewy-test.kpsazc.dgtl.kroger.com'
    }
    if (env == 'perf') {
        config.hostUrl= 'https://pay-gateway-eus2.gatewy-perf.kpsazc.dgtl.kroger.com';
        config.messageMaker_host= 'https://pay-msg-mkr-eus2.gatewy-perf.kpsazc.dgtl.kroger.com'
    }
    if (env == 'stage') {
        config.hostUrl= 'https://pay-gateway-eus2.gatewy-stage.kpsazc.dgtl.kroger.com';
        config.messageMaker_host= 'https://pay-msg-mkr-eus2.gatewy-stage.kpsazc.dgtl.kroger.com'
    }

    if (cmdHostUrl !=null && cmdHostUrl!='') {
        config.hostUrl = cmdHostUrl
    }
    return config;
}