using System;
using System.Data;

namespace ctorx.Core.Data
{
	public class SqlQueryCommand : AbstractDataCommand
	{
		/// <summary>
		/// ctor the Mighty
		/// </summary>
		public SqlQueryCommand(IDataProvider provider, string commandText) : base(provider, CommandType.Text, commandText)
		{
			if(string.IsNullOrWhiteSpace(commandText))
			{
				throw new ArgumentNullException("commandText");
			}
		}

		/// <summary>
		/// Makes a Data Command for use with a Stored Procedure
		/// </summary>
		public static IDataCommand Make(IDataProvider provider, string queryText)
		{
			return new SqlQueryCommand(provider, queryText);
		}
	}
}