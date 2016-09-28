using System;
using System.Data.Common;
using System.Data;
using System.Data.Entity;
using System.Data.Entity.Core.Common;
using System.Data.Entity.Infrastructure;

namespace ctorx.Core.Data
{
	public class NpgsqlDataProvider : IDataProvider
	{
        public string InvariantName { get; } = "Npgsql";

        public DbCommand GetDbCommand(CommandType commandType, string commandText)
		{
			DbCommand command = GetInstance<DbCommand>("Npgsql.NpgsqlCommand,Npgsql");
			command.CommandText = commandText;
			command.CommandType = commandType;
			return command;
		}

        public DbParameter GetDbParameter(string parameterName, object value)
		{
			return GetInstance<DbParameter>("Npgsql.NpgsqlParameter,Npgsql", parameterName, value);
		}

        public DbConnection GetDbConnection(string connectionString)
		{
			return GetInstance<DbConnection>("Npgsql.NpgsqlConnection,Npgsql", connectionString);
		}

        public DbDataAdapter GetDbDataAdapter(DbCommand command)
		{
			return GetInstance<DbDataAdapter>("Npgsql.NpgsqlDataAdapter,Npgsql", command);
		}

        public DbProviderFactory GetDbProviderFactory()
		{
			return (DbProviderFactory)Type.GetType("Npgsql.NpgsqlFactory,Npgsql").GetField("Instance").GetValue(null);
		}

        public DbProviderServices GetDbProviderServices()
		{
			return (DbProviderServices)Type.GetType("Npgsql.NpgsqlServices,EntityFramework6.Npgsql").GetProperty("Instance").GetValue(null, null);
		}

        public IDbConnectionFactory GetConnectionFactory()
		{
			return GetInstance<IDbConnectionFactory>("Npgsql.NpgsqlConnectionFactory,EntityFramework6.Npgsql");
		}

        /// <summary>
        /// Gets an instance of className, passing arguments, and cast it to T
        /// </summary>
        private T GetInstance<T>(string className, params Object[] arguments)
        {
            Type type = Type.GetType(className);
            if (type == null)
                throw new DllNotFoundException("Could not load type " + className);

            return (T)Activator.CreateInstance(type, arguments);
        }
	}
}
