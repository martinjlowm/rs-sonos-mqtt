use ntex::time::Seconds;
use ntex::{service::fn_service, util::Ready};
use rustls::{Certificate, ClientConfig, PrivateKey, RootCertStore};
use rustls_pemfile::{certs, rsa_private_keys};
// use rustls_pki_types::{CertificateDer,PrivateKeyDer};
use anyhow::{bail, Context, Result};
use futures::prelude::*;
use ntex::connect::rustls::Connector;
use ntex_mqtt::v3;
use std::fs::File;
use std::io::BufReader;
use std::time::Duration;
use tracing::{error, info};

#[derive(Debug)]
struct Error;

impl From<()> for Error {
    fn from(_: ()) -> Self {
        Error
    }
}
// impl std::convert::TryFrom<Error> for v3::PublishAck {
//     type Error = Error;

//     fn try_from(err: Error) -> Result<Self, Self::Error> {
//         Err(err)
//     }
// }

fn extract_connection_details(
) -> Result<(String, String, RootCertStore, Vec<Certificate>, PrivateKey)> {
    let Ok(endpoint) = std::env::var("AWS_ENDPOINT") else {
        bail!("AWS_ENDPOINT not set")
    };

    let Ok(client_id) = std::env::var("CLIENT_ID") else {
        bail!("CLIENT_ID not set")
    };

    let Ok(root_certificate_path) = std::env::var("ROOT_CERTIFICATE_PATH") else {
        bail!("ROOT_CERTIFICATE_PATH not set")
    };

    let Ok(certificate_path) = std::env::var("CERTIFICATE_PATH") else {
        bail!("CERTIFICATE_PATH not set")
    };

    let Ok(private_key_path) = std::env::var("PRIVATE_KEY_PATH") else {
        bail!("PRIVATE_KEY_PATH not set")
    };

    let root_certificate_file =
        File::open(root_certificate_path).context("Root certificate file")?;
    let certificate_file = File::open(certificate_path).context("Certificate file")?;
    let private_key_file = File::open(private_key_path).context("Private key file")?;

    let mut root_certificate_store = RootCertStore::empty();
    root_certificate_store
        .add_parsable_certificates(certs(&mut BufReader::new(root_certificate_file))?.as_slice());

    let private_key =
        PrivateKey(rsa_private_keys(&mut BufReader::new(private_key_file))?.remove(0));
    let certificates: Vec<_> = certs(&mut BufReader::new(certificate_file))?
        .iter()
        .map(|c| Certificate(c.to_vec()))
        .collect();
    // let certificates = certs(&mut BufReader::new(certificate_file)).filter_map(|c| c.ok()).collect::<Vec<_>>();

    if root_certificate_store.is_empty() {
        bail!("No valid PEM structures in the root certificate file")
    }

    if certificates.is_empty() {
        bail!("No valid PEM structures in the certificate file")
    }

    Ok((
        endpoint,
        client_id,
        root_certificate_store,
        certificates,
        private_key,
    ))
}

#[ntex::main]
async fn main() -> Result<()> {
    let (endpoint, client_id, root_certificates, certificates, private_key) =
        extract_connection_details()?;

    tracing_subscriber::fmt::init();

    let mut devices = sonor::discover(Duration::from_secs(5)).await?;

    while let Some(device) = devices.try_next().await? {
        let name = device.name().await?;
        println!("- {}", name);
    }
    info!("asdada after found no devices");
    // 1. Discover Sonos
    // 2. Once discovered, proceed to setting up MQTT client subscription again AWS
    // 3. Run Sonos from MQTT events -> set up Axum to serve local files and send sonos the URL

    let tls_config = ClientConfig::builder()
        .with_safe_defaults()
        .with_root_certificates(root_certificates)
        .with_client_auth_cert(certificates, private_key)
        .unwrap();

    let client = v3::client::MqttConnector::new(format!("{}:8883", endpoint.as_str().to_owned()))
        .connector(Connector::new(dbg!(tls_config)))
        .client_id(client_id.as_str().to_owned())
        .max_packet_size(0)
        .keep_alive(Seconds(30))
        .connect()
        .await
        .unwrap();

    let sink = client.sink();

    let router = client.resource(
        format!("sonos/{client_id}/play"),
        |pkt: v3::Publish| async move {
            // serde deserialize, if good, proceeed and publish to play/accepted, if bad, publish to play/rejected
            // let request = pkt.payload().into();
            info!("play request");
            Ok(())
        },
    );
    let task = ntex::rt::spawn(router.start(fn_service(
        |control_message: v3::client::ControlMessage<Error>| match control_message {
            v3::client::ControlMessage::Publish(msg) => {
                info!(
                    "incoming publish: {:?} -> {:?} payload {:?}",
                    msg.packet().packet_id,
                    msg.packet().topic,
                    msg.packet().payload
                );
                // Find sound file on web server, process the length of it and update Sonos preset with a link to the file asset
                Ready::Ok(msg.ack())
            }
            v3::client::ControlMessage::Closed(msg) => {
                info!("Server closed connection: {:?}", msg);
                Ready::Ok(msg.ack())
            }
            v3::client::ControlMessage::Error(msg) => {
                error!("Codec error: {:?}", msg);
                Ready::Ok(msg.ack())
            }
            v3::client::ControlMessage::ProtocolError(msg) => {
                error!("Protocol error: {:?}", msg);
                Ready::Ok(msg.ack())
            }
            v3::client::ControlMessage::PeerGone(msg) => {
                info!("Peer closed connection: {:?}", msg.err());
                Ready::Ok(msg.ack())
            }
        },
    )));

    sink.subscribe()
        .topic_filter(
            format!("sonos/{client_id}/+").into(),
            v3::codec::QoS::AtLeastOnce,
        )
        .send()
        .await
        .unwrap();

    match task.await {
        Ok(_) => info!("Doneso!"),
        Err(e) => error!("Yikes! {}", e),
    };

    // let addr = SocketAddr::from(([127, 0, 0, 1], port));
    // let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    // tracing::debug!("listening on {}", listener.local_addr().unwrap());
    // axum::serve(listener, app.layer(TraceLayer::new_for_http()))
    //     .await
    //     .unwrap();

    Ok(())
}
