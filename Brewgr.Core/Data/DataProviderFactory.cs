using System;
using System.Linq;

namespace ctorx.Core.Data
{
    public class DataProviderFactory
    {
        private static readonly string[] VALID_PROVIDERS = { "SqlClient", "Npgsql" };
        private static readonly string CLASS_PREFIX = "ctorx.Core.Data.";
        private static readonly string CLASS_SUFFIX = "DataProvider";

        /// <summary>
        /// Gets the correct provider class for the given providerName
        /// Assuming the format ctorx.Core.Data.{providerName}DataProvider
        /// </summary>
        public static IDataProvider Make(string providerName)
        {
            // If the provider name is invalid, fallback to SqlClient as the default
            if (!VALID_PROVIDERS.Contains(providerName))
            {
                providerName = "SqlClient";
            }

            string className = CLASS_PREFIX + providerName + CLASS_SUFFIX;

            Type type = Type.GetType(className);
            if (type == null)
                throw new DllNotFoundException("Could not load type " + className);

            return (IDataProvider)Activator.CreateInstance(type);
        }
    }
}

