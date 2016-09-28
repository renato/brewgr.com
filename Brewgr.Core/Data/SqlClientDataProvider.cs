using System;
using System.Data.Common;
using System.Data.SqlClient;
using System.Data;
using System.Data.Entity.Core.Common;
using System.Data.Entity.Infrastructure;
using System.Data.Entity.SqlServer;

namespace ctorx.Core.Data
{
	public class SqlClientDataProvider : IDataProvider
	{
        public string InvariantName { get; } = "SqlClient";


        public DbCommand GetDbCommand(CommandType commandType, string commandText)
		{
			return new SqlCommand(commandText) {CommandType = commandType};
		}

        public DbParameter GetDbParameter(string parameterName, object value)
		{
			return new SqlParameter(parameterName, value);
		}

        public DbConnection GetDbConnection(string connectionString)
		{
			return new SqlConnection(connectionString);
		}

        public DbDataAdapter GetDbDataAdapter(DbCommand command)
		{
			if (command is SqlCommand)
			{
				return new SqlDataAdapter((SqlCommand)command);
			}
			else
			{
				throw new ArgumentException("command argument must be of type SqlCommand");
			}	
		}

        public DbProviderFactory GetDbProviderFactory()
		{
			return SqlClientFactory.Instance;
		}

        public DbProviderServices GetDbProviderServices()
		{
			return SqlProviderServices.Instance;
		}

        public IDbConnectionFactory GetConnectionFactory()
		{
			return new SqlConnectionFactory();
		}
	}
}

