using System;
using ctorx.Core.Data;
using System.Collections.Generic;
using System.Linq;
using System.Data.Entity.Infrastructure;
using System.Data.Entity.Infrastructure.DependencyResolution;

namespace ctorx.Core.Data
{
    public class DbProviderDependencyResolver : IDbDependencyResolver
    {
        public IDataProvider Provider { get; }

        /// <summary>
        /// ctor the Mighty
        /// </summary>
        public DbProviderDependencyResolver(IDataProvider provider)
        {
            Provider = provider;
        }

        /// <summary>
        /// Gets the Service class of a given Type
        /// </summary>
        public object GetService(Type type, object key)
        {
            EServiceType servType;

            if (Enum.TryParse(type.Name, true, out servType))
            {
                switch (servType) {
                    case EServiceType.DbProviderFactory:
                        return Provider.GetDbProviderFactory();
                    case EServiceType.IDbConnectionFactory:
                        return Provider.GetConnectionFactory();
                    case EServiceType.DbProviderServices:
                        return Provider.GetDbProviderServices();
                    case EServiceType.IProviderInvariantName:
                        return new InvariantName(Provider.InvariantName);
                }
            }

            return null;
        }

        public IEnumerable<object> GetServices(Type type, object key)
        {
            var service = GetService(type, key);
            return service == null ? Enumerable.Empty<object>() : new[] { service };
        }

        internal class InvariantName : IProviderInvariantName
        {
            public string Name { get; }

            public InvariantName(string name) {
                Name = name;
            }
        }

        internal enum EServiceType
        {
            DbProviderFactory,
            DbProviderServices,
            IDbConnectionFactory,
            IProviderInvariantName
        }
    }
}

