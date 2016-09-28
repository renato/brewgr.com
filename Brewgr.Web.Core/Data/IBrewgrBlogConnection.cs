using System;

namespace Brewgr.Web.Core.Data
{
	public interface IBrewgrBlogConnection
	{
		/// <summary>
		/// Gets the connection string
		/// </summary>
		string ConnectionString { get; }

		/// <summary>
		/// Gets the provider name
		/// </summary>
		string ProviderName { get; }
	}
}