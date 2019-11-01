## [1.0.0-dev.6]
Made PrivateImmutableCollection and PrivateCollection proxies to actual
ImmutableCollection and Collection implementations.

## [1.0.0-dev.5]
Introduce PrivateCollection amd PrivateImmutableCollection.

## [1.0.0-dev.4]
Fix DataSourceServant type definition in _BaseCollection, 
ImmutableCollection and Collection.

## [1.0.0-dev.3]
Added ordering support for results of Specification.

## [1.0.0-dev.2]
Create a separate ReadonlyDataSource abstraction, so that data sources
that only allow querying would not have to implement modifiable 
DataSource class.

## [1.0.0-dev.1]
Initial implementation of collection oriented repositories with no
actual implementations at the moment.