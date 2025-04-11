package com.kroger.payments.gatewayEventConsumer;

import static io.confluent.kafka.schemaregistry.client.SchemaRegistryClientConfig.BASIC_AUTH_CREDENTIALS_SOURCE;
import static io.confluent.kafka.schemaregistry.client.SchemaRegistryClientConfig.USER_INFO_CONFIG;
import static io.confluent.kafka.serializers.AbstractKafkaSchemaSerDeConfig.SCHEMA_REGISTRY_URL_CONFIG;
import static io.confluent.kafka.serializers.KafkaAvroDeserializerConfig.SPECIFIC_AVRO_READER_CONFIG;
import static java.util.concurrent.TimeUnit.SECONDS;
import static org.apache.kafka.clients.CommonClientConfigs.SECURITY_PROTOCOL_CONFIG;
import static org.apache.kafka.clients.consumer.ConsumerConfig.*;
import static org.apache.kafka.common.config.SaslConfigs.*;

import com.google.common.collect.Lists;
import com.google.common.util.concurrent.Uninterruptibles;
import com.kroger.desp.commons.kcp.payments.EventHeader;
import com.kroger.desp.events.kcp.payments.EGiftCardActivation;
import java.time.Duration;
import java.time.Instant;
import java.util.List;
import java.util.Optional;
import java.util.Properties;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Function;
import java.util.function.Supplier;
import org.apache.avro.specific.SpecificRecord;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import reactor.core.Disposable;
import reactor.kafka.receiver.KafkaReceiver;
import reactor.kafka.receiver.ReceiverOptions;

public class ReactiveKafkaConsumer {

  private static final Logger logger = LoggerFactory.getLogger(ReactiveKafkaConsumer.class);

  private static final String TOPIC_NAME = "kcp-payments";
  private final ConcurrentHashMap<String, List<SpecificRecord>> events = new ConcurrentHashMap<>();

  private final Disposable disposable;

  public ReactiveKafkaConsumer() {
    final ReceiverOptions<String, SpecificRecord> receiverOptions =
        ReceiverOptions.<String, SpecificRecord>create(CONSUMER_PROPERTIES.get())
            .subscription(List.of(TOPIC_NAME))
            .commitInterval(Duration.ofSeconds(20))
            .commitBatchSize(5);

    final var kafkaReceiver = KafkaReceiver.create(receiverOptions);

    this.disposable =
        kafkaReceiver
            .receiveAutoAck()
            .concatMap(Function.identity())
            .map(this::eventAndHeaderOrNull)
            .filter(Optional::isPresent)
            .map(Optional::get)
            .map(this::putOrAdd)
            .subscribe();

    // Let's wait for kafka to
    // Sleep for 5 seconds without interruption
    Uninterruptibles.sleepUninterruptibly(50, SECONDS);
  }

  record EventAndHeader(SpecificRecord specificRecord, EventHeader eventHeader) {}

  private Optional<EventAndHeader> eventAndHeaderOrNull(
      final ConsumerRecord<String, SpecificRecord> consumerRecord) {

    final SpecificRecord specificRecord = consumerRecord.value();
    final var eventHeader = eventHeaderOrNull(specificRecord);
    if (eventHeader == null) {
      return Optional.empty();
    }
    return Optional.of(new EventAndHeader(specificRecord, eventHeader));
  }

  private String putOrAdd(final EventAndHeader eventAndHeader) {
    final EventHeader eventHeader = eventAndHeader.eventHeader;
    final EGiftCardActivation eGiftCardActivation = (EGiftCardActivation) eventAndHeader.specificRecord;
    final Instant now = Instant.now();
    final Instant eventHeaderTime = Instant.ofEpochMilli(eventHeader.getTime());

    logger.info(
        "Received event with header id: {} and loyalty id: {} which is created at :{}, and we received at: {} ,with " +
                "difference: {}",
        eventHeader.getId(),
        eGiftCardActivation.getLoyaltyId(),
        eventHeaderTime,
        now,
        Duration.between(eventHeaderTime, now).toMillis());

    if (events.containsKey(eventHeader.getId())) {
      events.get(eGiftCardActivation.getLoyaltyId()).add(eventAndHeader.specificRecord);
    } else {
      events.put(eGiftCardActivation.getLoyaltyId(), Lists.newArrayList(eventAndHeader.specificRecord));
    }
    return eGiftCardActivation.getLoyaltyId();
  }

  public List<SpecificRecord> getOr(final String key) {
    return events.getOrDefault(key, List.of());
  }

  public void close() {
    disposable.dispose();
  }

  // Lazy initialization using Supplier
  private static final Supplier<Properties> CONSUMER_PROPERTIES =
      () -> {
        Properties properties = new Properties();
        properties.put(BOOTSTRAP_SERVERS_CONFIG, System.getProperty("server"));
        properties.put(GROUP_ID_CONFIG, TOPIC_NAME.concat(UUID.randomUUID().toString()));
        properties.put(SPECIFIC_AVRO_READER_CONFIG, true);
        properties.put(SECURITY_PROTOCOL_CONFIG, System.getProperty("security_protocol"));
        properties.put(SASL_MECHANISM, System.getProperty("sasl_mechanism"));
        properties.put(SASL_JAAS_CONFIG, System.getProperty("JAAS_CONFIG_CONSUMER"));
        properties.put(SASL_LOGIN_CALLBACK_HANDLER_CLASS, System.getProperty("authentication_implmentation_class"));
        properties.put(SCHEMA_REGISTRY_URL_CONFIG, System.getProperty("registryurl"));
        properties.put(BASIC_AUTH_CREDENTIALS_SOURCE, "USER_INFO");
        properties.put(USER_INFO_CONFIG, System.getProperty("user_info_credential"));
        properties.put(KEY_DESERIALIZER_CLASS_CONFIG, System.getProperty("key_deserializer"));
        properties.put(VALUE_DESERIALIZER_CLASS_CONFIG, System.getProperty("value_deserializer"));
        properties.put(ENABLE_AUTO_COMMIT_CONFIG, false);
        properties.put(AUTO_OFFSET_RESET_CONFIG, "latest");

        return properties;
      };

  private static EventHeader eventHeaderOrNull(final SpecificRecord specificRecord) {
    if (specificRecord instanceof final EGiftCardActivation eGiftCardActivation) {
      return eGiftCardActivation.getEventHeader();
    }

    return null;
  }
}
