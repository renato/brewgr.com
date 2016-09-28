using System.Data.Common;
using System.Data;
using System.Data.Entity.Infrastructure;
using System.Data.Entity.Core.Common;

namespace ctorx.Core.Data
{
    public interface IDataProvider
	{
        /// <summary>
        /// The Invariant Name for the Data Provider
        /// </summary>
        string InvariantName { get; }

		/// <summary>
		/// Resolves the Provider Class for DbCommand
		/// </summary>
		DbCommand GetDbCommand(CommandType commandType, string commandText);

		/// <summary>
		/// Resolves the Provider Class for DbParameter
		/// </summary>
		DbParameter GetDbParameter(string parameterName, object value);

		/// <summary>
		/// Resolves the Provider Class for DbConnection
		/// </summary>
		DbConnection GetDbConnection(string connectionString);

		/// <summary>
		/// Resolves the Provider Class for DbDataAdapter
		/// </summary>
		DbDataAdapter GetDbDataAdapter(DbCommand command);

		/// <summary>
		/// Resolves the Provider Class for DbProviderFactory
		/// </summary>
		DbProviderFactory GetDbProviderFactory();

		/// <summary>
		/// Resolves the Provider Class for DbProviderServices
		/// </summary>
		DbProviderServices GetDbProviderServices();

        /// <summary>
        /// Resolves the Provider Class for IDbConnectionFactory
        /// </summary>
        IDbConnectionFactory GetConnectionFactory();
	}
}

