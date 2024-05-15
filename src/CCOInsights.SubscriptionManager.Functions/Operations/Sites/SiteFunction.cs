﻿using static Microsoft.Azure.Management.Fluent.Azure;

namespace CCOInsights.SubscriptionManager.Functions.Operations.Sites;

[OperationDescriptor(DashboardType.Infrastructure, nameof(SiteFunction))]
public class SiteFunction : IOperation
{
    private readonly IAuthenticated _authenticatedResourceManager;
    private readonly ISiteUpdater _updater;

    public SiteFunction(IAuthenticated authenticatedResourceManager, ISiteUpdater updater)
    {
        _authenticatedResourceManager = authenticatedResourceManager;
        _updater = updater;
    }

    [Function(nameof(SiteFunction))]
    public async Task Execute([ActivityTrigger] string name, FunctionContext executionContext, CancellationToken cancellationToken = default)
    {
        var subscriptions = await _authenticatedResourceManager.Subscriptions.ListAsync(cancellationToken: cancellationToken);
        await subscriptions.AsyncParallelForEach(async subscription =>
            await _updater.UpdateAsync(executionContext.InvocationId, subscription, cancellationToken), 1);
    }

}
