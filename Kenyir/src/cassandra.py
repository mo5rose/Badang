# kenyir/src/cassandra.py
from cassandra.cluster import Cluster

cluster = Cluster(['127.0.0.1'])
session = cluster.connect()

session.execute("CREATE KEYSPACE IF NOT EXISTS kenyir WITH replication = {'class': 'SimpleStrategy', 'replication_factor': 1}")
session.execute("USE kenyir")
session.execute("CREATE TABLE IF NOT EXISTS meter_data (timestamp text PRIMARY KEY, value float)")