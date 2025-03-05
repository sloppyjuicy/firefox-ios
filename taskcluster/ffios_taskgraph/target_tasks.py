# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.


from taskgraph.target_tasks import register_target_task


@register_target_task('l10n_screenshots')
def target_tasks_default(full_task_graph, parameters, graph_config):
    """Target the tasks which have indicated they should be run on this project
    via the `run_on_projects` attributes."""
    def filter(task, parameters):
        return task.kind == "generate-screenshots"

    return [l for l, t in full_task_graph.tasks.items() if filter(t, parameters)]

@register_target_task('bitrise_performance_test')
def target_tasks_default(full_task_graph, parameters, graph_config):
    """Target the tasks which have indicated they should be run on this project
    via the `run_on_projects` attributes."""
    def filter(task, parameters):
        return task.kind == "bitrise-performance"

    return [l for l, t in full_task_graph.tasks.items() if filter(t, parameters)]

@register_target_task('firebase_performance_test')
def target_tasks_default(full_task_graph, parameters, graph_config):
    """Target the tasks which have indicated they should be run on this project
    via the `run_on_projects` attributes."""
    def filter(task, parameters):
        return task.kind == "firebase-performance"

    return [l for l, t in full_task_graph.tasks.items() if filter(t, parameters)]
