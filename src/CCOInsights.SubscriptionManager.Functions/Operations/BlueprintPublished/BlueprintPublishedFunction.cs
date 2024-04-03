﻿using System.Threading.Tasks;
using CCOInsights.SubscriptionManager.Helpers;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.DurableTask;
using static Microsoft.Azure.Management.Fluent.Azure;

namespace CCOInsights.SubscriptionManager.Functions.Operations.BlueprintPublished;

[OperationDescriptor(DashboardType.Governance, nameof(BlueprintPublishedFunction))]
public class BlueprintPublishedFunction : IOperation
{
    private readonly IAuthenticated _authenticatedResourceManager;
    private readonly IBlueprintPublishedUpdater _updater;

    public BlueprintPublishedFunction(IAuthenticated authenticatedResourceManager, IBlueprintPublishedUpdater updater)
    {
        _authenticatedResourceManager = authenticatedResourceManager;
        _updater = updater;

    }

    [FunctionName(nameof(BlueprintPublishedFunction))]
    public async Task Execute([ActivityTrigger] IDurableActivityContext context, System.Threading.CancellationToken cancellationToken = default)
    {
        var subscriptions = await _authenticatedResourceManager.Subscriptions.ListAsync(cancellationToken: cancellationToken);
        await subscriptions.AsyncParallelForEach(async subscription =>
            await _updater.UpdateAsync(context.InstanceId, subscription, cancellationToken), 1);
    }
}