using System;
using System.Data;

namespace ctorx.Core.Data
{
	/// <summary>
	/// Used to execute stored procedures
	/// </summary>
	public class StoredProcedureCommand : AbstractDataCommand
	{
		/// <summary>
		/// ctor the Mighty
		/// </summary>
		private StoredProcedureCommand(IDataProvider provider, string procedureName) : base(provider, CommandType.StoredProcedure, procedureName)
		{
			if(string.IsNullOrWhiteSpace(procedureName))
			{
				throw new ArgumentNullException("procedureName");
			}
		}

		/// <summary>
		/// Makes a Data Command for use with a Stored Procedure
		/// </summary>
		public static IDataCommand Make(IDataProvider provider, string procedureName)
		{
			return new StoredProcedureCommand(provider, procedureName);
		}
	}
}